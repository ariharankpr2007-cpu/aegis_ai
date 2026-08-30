import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  Position? _position;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw Exception('Turn on Location in the Android emulator settings.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is permanently denied. Open app settings to allow it.');
      }

      final position = await Geolocator.getCurrentPosition(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
  ),
);

final user = FirebaseAuth.instance.currentUser;

if (user != null) {
  await FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid)
      .update({
    "latitude": position.latitude,
    "longitude": position.longitude,
    "locationAccuracy": position.accuracy,
    "locationUpdatedAt": Timestamp.now(),
  });
}

if (!mounted) return;

setState(() => _position = position);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text('Live Location'),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh location',
            onPressed: _loading ? null : _getLocation,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Getting your current location…'),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: _ErrorCard(
                      message: _error!,
                      onRetry: _getLocation,
                    ),
                  )
                : _position == null
                    ? Center(
                        child: _ErrorCard(
                          message: 'Location is unavailable.',
                          onRetry: _getLocation,
                        ),
                      )
                    : _LocationCard(
                        position: _position!,
                        onRefresh: _getLocation,
                      ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.position,
    required this.onRefresh,
  });

  final Position position;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final currentLocation = LatLng(
      position.latitude,
      position.longitude,
    );

    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: currentLocation,
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.aegis_ai',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLocation,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 15),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Your Current Location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                _CoordinateRow(
                  label: 'Latitude',
                  value: position.latitude.toStringAsFixed(6),
                ),

                const SizedBox(height: 6),

                _CoordinateRow(
                  label: 'Longitude',
                  value: position.longitude.toStringAsFixed(6),
                ),

                const SizedBox(height: 6),

                _CoordinateRow(
                  label: 'Accuracy',
                  value:
                      '${position.accuracy.toStringAsFixed(0)} m',
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Location'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CoordinateRow extends StatelessWidget {
  const _CoordinateRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_outlined, size: 54, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('Location unavailable', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
