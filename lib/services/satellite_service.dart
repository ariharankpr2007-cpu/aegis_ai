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
  // Search a wide window around the incident.
  final recentResults = await searchSentinel2(
    latitude: latitude,
    longitude: longitude,
    startDate: incidentDate.subtract(
      const Duration(days: 30),
    ),
    endDate: incidentDate.add(
      const Duration(days: 1),
    ),
    radiusKm: radiusKm,
  );

  // Search an earlier period for the "before" image.
  final previousCenter = incidentDate.subtract(
    const Duration(days: 30),
  );

  final previousResults = await searchSentinel2(
    latitude: latitude,
    longitude: longitude,
    startDate: previousCenter.subtract(
      const Duration(days: 30),
    ),
    endDate: previousCenter.add(
      const Duration(days: 1),
    ),
    radiusKm: radiusKm,
  );

  Map<String, dynamic>? chooseBest(
    List<Map<String, dynamic>> scenes,
  ) {
    if (scenes.isEmpty) return null;

    // Lowest cloud cover is preferred.
    final sorted = [...scenes];

    sorted.sort((a, b) {
      final aProperties =
          a['properties'] as Map<String, dynamic>?;

      final bProperties =
          b['properties'] as Map<String, dynamic>?;

      final aCloud =
          (aProperties?['eo:cloud_cover'] as num?)
              ?.toDouble() ??
              100.0;

      final bCloud =
          (bProperties?['eo:cloud_cover'] as num?)
              ?.toDouble() ??
              100.0;

      return aCloud.compareTo(bCloud);
    });

    return sorted.first;
  }

  String? getPreviewUrl(
    Map<String, dynamic>? scene,
  ) {
    if (scene == null) return null;

    final assets =
        scene['assets'] as Map<String, dynamic>?;

    final rendered =
        assets?['rendered_preview']
            as Map<String, dynamic>?;

    return rendered?['href']?.toString();
  }

  String getSceneDate(
    Map<String, dynamic>? scene,
  ) {
    if (scene == null) {
      return 'Not available';
    }

    final properties =
        scene['properties']
            as Map<String, dynamic>?;

    return properties?['datetime']
            ?.toString() ??
        'Unknown';
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

  final recentScene =
      chooseBest(recentResults);

  final previousScene =
      chooseBest(previousResults);

  return {
    'recentImageUrl':
        getPreviewUrl(recentScene),

    'previousImageUrl':
        getPreviewUrl(previousScene),

    'recentDate':
        getSceneDate(recentScene),

    'previousDate':
        getSceneDate(previousScene),

    'recentCloudCover':
        getCloudCover(recentScene),

    'previousCloudCover':
        getCloudCover(previousScene),
  };
}
}