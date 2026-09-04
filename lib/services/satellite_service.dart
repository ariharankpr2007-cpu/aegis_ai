import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class SatelliteService {
  static const String _searchUrl =
      'https://planetarycomputer.microsoft.com/api/stac/v1/search';

  Future<List<Map<String, dynamic>>> searchSentinel2({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
    double radiusKm = 5,
  }) async {
    final latDelta = radiusKm / 111.0;

    final lonDelta =
        radiusKm /
        (111.0 * cos(latitude * pi / 180.0));

    final body = {
      'collections': ['sentinel-2-l2a'],
      'bbox': [
        longitude - lonDelta,
        latitude - latDelta,
        longitude + lonDelta,
        latitude + latDelta,
      ],
      'datetime':
          '${startDate.toUtc().toIso8601String()}'
          '/'
          '${endDate.toUtc().toIso8601String()}',
      'query': {
        'eo:cloud_cover': {
          'lt': 70,
        },
      },
      'limit': 10,
      'sortby': [
        {
          'field': 'properties.datetime',
          'direction': 'desc',
        },
      ],
    };

    final response = await http.post(
      Uri.parse(_searchUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/geo+json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Satellite search failed: '
        '${response.statusCode}\n'
        '${response.body}',
      );
    }

    final decoded =
        jsonDecode(response.body)
            as Map<String, dynamic>;

    final features =
        decoded['features'] as List<dynamic>? ?? [];

    return features
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<Map<String, dynamic>> getVerificationImagery({
  required double latitude,
  required double longitude,
  required DateTime incidentDate,
  double radiusKm = 5,
}) async {
  // Search recent imagery from the incident date backwards.
  final recentResults = await searchSentinel2(
    latitude: latitude,
    longitude: longitude,
    startDate: incidentDate.subtract(
      const Duration(days: 14),
    ),
    endDate: incidentDate,
    radiusKm: radiusKm,
  );

  if (recentResults.isEmpty) {
    return {
      'recentImageUrl': null,
      'previousImageUrl': null,
      'recentDate': 'Not available',
      'previousDate': 'Not available',
      'recentCloudCover': null,
      'previousCloudCover': null,
    };
  }

  Map<String, dynamic>? bestScene(
    List<Map<String, dynamic>> scenes,
  ) {
    if (scenes.isEmpty) return null;

    final sorted = [...scenes];

    sorted.sort((a, b) {
      final aProperties =
          a['properties'] as Map<String, dynamic>?;

      final bProperties =
          b['properties'] as Map<String, dynamic>?;

      final aCloud =
          (aProperties?['eo:cloud_cover'] as num?)
                  ?.toDouble() ??
              100;

      final bCloud =
          (bProperties?['eo:cloud_cover'] as num?)
                  ?.toDouble() ??
              100;

      final aDate =
          DateTime.tryParse(
            aProperties?['datetime']?.toString() ?? '',
          );

      final bDate =
          DateTime.tryParse(
            bProperties?['datetime']?.toString() ?? '',
          );

      // First prefer lower cloud cover.
      final cloudCompare =
          aCloud.compareTo(bCloud);

      if (cloudCompare != 0) {
        return cloudCompare;
      }

      // If cloud cover is similar, prefer newer.
      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }

      return 0;
    });

    return sorted.first;
  }

  String? getPreview(
    Map<String, dynamic>? scene,
  ) {
    if (scene == null) return null;

    final assets =
        scene['assets']
            as Map<String, dynamic>?;

    final preview =
        assets?['rendered_preview']
            as Map<String, dynamic>?;

    return preview?['href']?.toString();
  }

  DateTime? getSceneDate(
    Map<String, dynamic>? scene,
  ) {
    if (scene == null) return null;

    final properties =
        scene['properties']
            as Map<String, dynamic>?;

    return DateTime.tryParse(
      properties?['datetime']?.toString() ?? '',
    );
  }

  double? getCloudCover(
    Map<String, dynamic>? scene,
  ) {
    if (scene == null) return null;

    final properties =
        scene['properties']
            as Map<String, dynamic>?;

    return (properties?['eo:cloud_cover'] as num?)
        ?.toDouble();
  }

  // Sort all recent scenes by date, newest first.
  final recentSorted = [...recentResults];

  recentSorted.sort((a, b) {
    final aDate = getSceneDate(a);
    final bDate = getSceneDate(b);

    if (aDate == null || bDate == null) {
      return 0;
    }

    return bDate.compareTo(aDate);
  });

  // Prefer the newest reasonably clear image.
  Map<String, dynamic>? recentScene;

  for (final scene in recentSorted) {
    final cloud = getCloudCover(scene);

    if (cloud != null && cloud <= 50) {
      recentScene = scene;
      break;
    }
  }

  // If no scene is below 50% cloud, use the clearest scene.
  recentScene ??= bestScene(recentResults);

  final recentDate = getSceneDate(recentScene);

  if (recentDate == null) {
    return {
      'recentImageUrl': getPreview(recentScene),
      'previousImageUrl': null,
      'recentDate': 'Unknown',
      'previousDate': 'Not available',
      'recentCloudCover':
          getCloudCover(recentScene),
      'previousCloudCover': null,
    };
  }

  // Search only BEFORE the selected recent image.
  final previousResults =
      await searchSentinel2(
    latitude: latitude,
    longitude: longitude,
    startDate: recentDate.subtract(
      const Duration(days: 14),
    ),
    endDate: recentDate.subtract(
      const Duration(days: 1),
    ),
    radiusKm: radiusKm,
  );

  Map<String, dynamic>? previousScene;

  if (previousResults.isNotEmpty) {
    // Sort newest first.
    previousResults.sort((a, b) {
      final aDate = getSceneDate(a);
      final bDate = getSceneDate(b);

      if (aDate == null || bDate == null) {
        return 0;
      }

      return bDate.compareTo(aDate);
    });

    // Prefer an image within roughly 7 days.
    for (final scene in previousResults) {
      final sceneDate =
          getSceneDate(scene);

      if (sceneDate == null) continue;

      final gap =
          recentDate.difference(sceneDate).inDays;

      final cloud = getCloudCover(scene);

      if (gap >= 1 &&
    gap <= 2 &&
    cloud != null &&
    cloud <= 50) {
        previousScene = scene;
        break;
      }
    }

    // If none found, use the nearest reasonably clear scene.
    previousScene ??= previousResults.firstWhere(
      (scene) {
        final cloud =
            getCloudCover(scene);

        return cloud != null &&
            cloud <= 70;
      },
      orElse: () => previousResults.first,
    );
  }

  final previousDate =
      getSceneDate(previousScene);

  return {
    'recentImageUrl':
        getPreview(recentScene),

    'previousImageUrl':
        getPreview(previousScene),

    'recentDate':
        recentDate.toIso8601String(),

    'previousDate':
        previousDate?.toIso8601String() ??
            'Not available',

    'recentCloudCover':
        getCloudCover(recentScene),

    'previousCloudCover':
        getCloudCover(previousScene),

    'gapDays':
        previousDate == null
            ? null
            : recentDate
                .difference(previousDate)
                .inDays,
  };
}
}