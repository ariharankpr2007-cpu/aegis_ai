import 'package:flutter/material.dart';

import '../../services/satellite_service.dart';

class SatelliteTestScreen extends StatefulWidget {
  const SatelliteTestScreen({super.key});

  @override
  State<SatelliteTestScreen> createState() =>
      _SatelliteTestScreenState();
}

class _SatelliteTestScreenState
    extends State<SatelliteTestScreen> {
  final SatelliteService _satelliteService =
      SatelliteService();

  bool _loading = false;
  String? _recentImageUrl;
String? _previousImageUrl;
  String _result = 'Press the button to search satellite imagery.';

  Future<void> _searchSatellite() async {
  setState(() {
    _loading = true;
    _result = 'Searching Sentinel-2 imagery...';
    _recentImageUrl = null;
    _previousImageUrl = null;
  });

  try {
    final imagery =
        await _satelliteService
            .getVerificationImagery(
      latitude: 13.0827,
      longitude: 80.2707,
      incidentDate:
          DateTime(2026, 8, 30),
      radiusKm: 5,
    );

    if (!mounted) return;

    final recentUrl =
        imagery['recentImageUrl']
            as String?;

    final previousUrl =
        imagery['previousImageUrl']
            as String?;

    if (recentUrl == null ||
        recentUrl.isEmpty) {
      setState(() {
        _result =
            'No recent Sentinel-2 imagery found.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _recentImageUrl = recentUrl;
      _previousImageUrl = previousUrl;

      _result =
    'SENTINEL-2 SATELLITE READY\n\n'
    'Recent date: '
    '${imagery["recentDate"]}\n'
    'Recent cloud cover: '
    '${imagery["recentCloudCover"] ?? "Unknown"}%\n\n'
    'Previous date: '
    '${imagery["previousDate"]}\n'
    'Previous cloud cover: '
    '${imagery["previousCloudCover"] ?? "Unknown"}%';

      _loading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _result =
          'SATELLITE ERROR:\n$e';
      _loading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Satellite API Test',
        ),
        backgroundColor:
            const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.satellite_alt,
              size: 80,
              color: Colors.blue,
            ),

            const SizedBox(height: 20),

            const Text(
              'AEGIS Satellite Search',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Test location: Chennai\n'
              'Radius: 5 km\n'
              'Date: 15–30 Aug 2026',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed:
                    _loading
                        ? null
                        : _searchSatellite,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.search,
                      ),
                label: Text(
                  _loading
                      ? 'SEARCHING...'
                      : 'SEARCH SATELLITE',
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
  child: SingleChildScrollView(
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          _result,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        if (_recentImageUrl != null) ...[
          const SizedBox(height: 20),

          const Text(
            'RECENT SATELLITE IMAGE',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(12),
            child: Image.network(
              _recentImageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder:
                  (context, child, progress) {
                if (progress == null) {
                  return child;
                }

                return const SizedBox(
                  height: 220,
                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                );
              },
              errorBuilder:
                  (context, error, stackTrace) {
                return Container(
                  height: 220,
                  alignment: Alignment.center,
                  child: const Text(
                    'Unable to load recent satellite image.',
                  ),
                );
              },
            ),
          ),
        ],

        if (_previousImageUrl != null) ...[
          const SizedBox(height: 25),

          const Text(
            'PREVIOUS SATELLITE IMAGE',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(12),
            child: Image.network(
              _previousImageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder:
                  (context, child, progress) {
                if (progress == null) {
                  return child;
                }

                return const SizedBox(
                  height: 220,
                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                );
              },
              errorBuilder:
                  (context, error, stackTrace) {
                return Container(
                  height: 220,
                  alignment: Alignment.center,
                  child: const Text(
                    'Unable to load previous satellite image.',
                  ),
                );
              },
            ),
          ),
        ],
      ],
    ),
  ),
),
          ],
        ),
      ),
    );
  }
}