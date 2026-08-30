import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ShelterScreen extends StatefulWidget {
  const ShelterScreen({super.key});

  @override
  State<ShelterScreen> createState() => _ShelterScreenState();
}

class _ShelterScreenState extends State<ShelterScreen> {
  bool _loading = true;
  String _error = '';
  Position? _position;
  static const String _latLngApiKey = 'latlng_qq68kxeb9itztl40nhcnrgj4dxcmgy5v';
  List<_Shelter> _liveShelters = [];

  static const _shelters = <_Shelter>[
    _Shelter(
      'Government Higher Secondary School',
      'Relief camp',
      '120 beds available',
      Icons.school_outlined,
    ),
    _Shelter(
      'District Community Hall',
      'Evacuation shelter',
      '85 beds available',
      Icons.home_work_outlined,
    ),
    _Shelter(
      'District Government Hospital',
      'Medical support',
      'Emergency care open',
      Icons.local_hospital_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

setState(() {
  _position = position;
});

try {
  await _loadShelters(position);
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Nearby facilities error: $e',
        ),
      ),
    );
  }
}

if (!mounted) return;

setState(() {
  _loading = false;
});
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
    'Unable to access your location. Please enable GPS and location permission, then try again.';
      });
    }
  }
  Future<void> _loadShelters(Position position) async {
  final uri = Uri.parse(
    'https://api.latlng.work/v1/places/nearby',
  ).replace(
    queryParameters: {
      'lat': position.latitude.toString(),
      'lon': position.longitude.toString(),
      'radius': '5000',
      'limit': '30',
    },
  );

  final response = await http
      .get(
        uri,
        headers: {
          'X-Api-Key': _latLngApiKey,
          'Accept': 'application/json',
        },
      )
      .timeout(const Duration(seconds: 20));

  if (response.statusCode != 200) {
    throw Exception(
      'Server error ${response.statusCode}: ${response.body}',
    );
  }

  final data =
      jsonDecode(response.body) as Map<String, dynamic>;

  final places =
      data['places'] as List<dynamic>? ?? [];

  final shelters = <_Shelter>[];

  for (final item in places) {
    if (item is! Map<String, dynamic>) continue;

    final latitude = item['lat'];
    final longitude = item['lon'];

    if (latitude is! num || longitude is! num) {
      continue;
    }

    final name =
        (item['name'] ?? 'Nearby facility').toString();

    final category =
        (item['category'] ?? '').toString().toLowerCase();

    IconData icon = Icons.location_city_outlined;
    String type = 'Nearby facility';
    String availability =
        'Verify emergency availability before travelling';

    if (category.contains('hospital')) {
      icon = Icons.local_hospital_outlined;
      type = 'Hospital / medical support';
      availability =
          'Medical facility — confirm emergency capacity';
    } else if (category.contains('clinic')) {
      icon = Icons.medical_services_outlined;
      type = 'Medical facility';
    } else if (category.contains('school') ||
        category.contains('college')) {
      icon = Icons.school_outlined;
      type = 'Public facility';
      availability =
          'May be used during emergencies — verify officially';
    } else if (category.contains('police')) {
      icon = Icons.local_police_outlined;
      type = 'Police facility';
    } else if (category.contains('fire')) {
      icon = Icons.local_fire_department_outlined;
      type = 'Fire / emergency service';
    }

    shelters.add(
      _Shelter(
        name,
        type,
        availability,
        icon,
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
      ),
    );
  }

  int priority(_Shelter shelter) {
  final type = shelter.type.toLowerCase();

  if (type.contains('shelter')) return 1;
  if (type.contains('fire')) return 2;
  if (type.contains('hospital')) return 3;
  if (type.contains('police')) return 4;
  if (type.contains('medical')) return 5;

  return 6;
}

shelters.sort((a, b) {
  final priorityCompare =
      priority(a).compareTo(priority(b));

  if (priorityCompare != 0) {
    return priorityCompare;
  }

  final aDistance = Geolocator.distanceBetween(
    position.latitude,
    position.longitude,
    a.latitude!,
    a.longitude!,
  );

  final bDistance = Geolocator.distanceBetween(
    position.latitude,
    position.longitude,
    b.latitude!,
    b.longitude!,
  );

  return aDistance.compareTo(bDistance);
});

  if (!mounted) return;

  setState(() {
    _liveShelters = shelters.take(20).toList();
  });
}

  double _distanceToShelter(_Shelter shelter) {
    if (_position == null ||
        shelter.latitude == null ||
        shelter.longitude == null) {
      return 0;
    }

    return Geolocator.distanceBetween(
          _position!.latitude,
          _position!.longitude,
          shelter.latitude!,
          shelter.longitude!,
        ) /
        1000;
  }

  Future<void> _openDirections(_Shelter shelter) async {
    final destination = shelter.latitude != null &&
            shelter.longitude != null
        ? '${shelter.latitude},${shelter.longitude}'
        : Uri.encodeComponent(shelter.name);

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination',
    );

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Maps.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Nearby Shelters'),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadLocation,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_off_outlined,
                          size: 55,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadLocation,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLocation,
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    children: [
                      const Text(
                        'Nearby emergency facilities',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Live nearby facilities based on map data. Confirm official emergency availability before travelling.',
                      ),
                      const SizedBox(height: 18),
                      if (_liveShelters.isEmpty)
  Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Column(
      children: [
        Icon(
          Icons.location_searching_outlined,
          size: 48,
          color: Colors.black54,
        ),
        SizedBox(height: 12),
        Text(
          'No mapped shelters found nearby',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Try refreshing or check nearby hospitals and community facilities.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ],
    ),
  )
else
  ..._liveShelters.map(
    (shelter) => _ShelterCard(
      shelter: shelter,
      distance: _distanceToShelter(shelter),
      onDirections: () => _openDirections(shelter),
    ),
  ),
                    ],
                  ),
                ),
    );
  }
}

class _Shelter {
  const _Shelter(
    this.name,
    this.type,
    this.availability,
    this.icon, {
    this.latitude,
    this.longitude,
  });

  final String name;
  final String type;
  final String availability;
  final IconData icon;
  final double? latitude;
  final double? longitude;
}

class _ShelterCard extends StatelessWidget {
  const _ShelterCard({
    required this.shelter,
    required this.distance,
    required this.onDirections,
  });

  final _Shelter shelter;
  final double distance;
  final VoidCallback onDirections;

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Wrap(
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Text(
                  shelter.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                _BuildPriorityBadge(type: shelter.type),

                const SizedBox(height: 20),

                _DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Facility type',
                  value: shelter.type,
                ),

                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Distance',
                  value: '${distance.toStringAsFixed(1)} km away',
                ),

                _DetailRow(
                  icon: Icons.info_outline,
                  label: 'Status',
                  value: shelter.availability,
                ),

                if (shelter.latitude != null &&
                    shelter.longitude != null)
                  _DetailRow(
                    icon: Icons.my_location_outlined,
                    label: 'Coordinates',
                    value:
                        '${shelter.latitude!.toStringAsFixed(5)}, '
                        '${shelter.longitude!.toStringAsFixed(5)}',
                  ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onDirections();
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Get Directions'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: const Color(0xFF0B3D91),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor:
                    Colors.orange.withValues(alpha: 0.14),
                child: Icon(
                  shelter.icon,
                  color: Colors.orange.shade800,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shelter.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    _BuildPriorityBadge(type: shelter.type),

                    const SizedBox(height: 5),

                    Text(
                      '${shelter.type} · ${distance.toStringAsFixed(1)} km away',
                    ),

                    const SizedBox(height: 5),

                    Text(
                      shelter.availability,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    OutlinedButton.icon(
                      onPressed: onDirections,
                      icon: const Icon(Icons.directions_outlined),
                      label: const Text('Directions'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF0B3D91),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _BuildPriorityBadge extends StatelessWidget {
  const _BuildPriorityBadge({
    required this.type,
  });

  final String type;

  @override
  Widget build(BuildContext context) {
    final value = type.toLowerCase();

    String label = 'PUBLIC FACILITY';
    IconData icon = Icons.location_city_outlined;

    if (value.contains('shelter')) {
      label = 'PRIORITY: SHELTER';
      icon = Icons.home_work_outlined;
    } else if (value.contains('fire')) {
      label = 'PRIORITY: FIRE & EMERGENCY';
      icon = Icons.local_fire_department_outlined;
    } else if (value.contains('hospital')) {
      label = 'PRIORITY: MEDICAL';
      icon = Icons.local_hospital_outlined;
    } else if (value.contains('police')) {
      label = 'PRIORITY: POLICE';
      icon = Icons.local_police_outlined;
    } else if (value.contains('medical')) {
      label = 'MEDICAL FACILITY';
      icon = Icons.medical_services_outlined;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: Colors.red.shade700,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}