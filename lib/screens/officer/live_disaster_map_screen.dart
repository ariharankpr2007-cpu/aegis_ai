import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveDisasterMapScreen extends StatelessWidget {
  const LiveDisasterMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Live Disaster Map"),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection("users")
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!snapshot.hasData) {
      return const Center(
        child: Text("Unable to load locations."),
      );
    }

    final users = snapshot.data!.docs;

    final markers = <Marker>[];

    for (final doc in users) {
      final data = doc.data() as Map<String, dynamic>;

      if (data["latitude"] == null ||
          data["longitude"] == null) {
        continue;
      }

      final latitude = (data["latitude"] as num).toDouble();
      final longitude = (data["longitude"] as num).toDouble();

      markers.add(
        Marker(
          point: LatLng(latitude, longitude),
          width: 50,
          height: 50,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 45,
          ),
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(13.0827, 80.2707),
        initialZoom: 11,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.aegis_ai',
        ),
        MarkerLayer(
          markers: markers,
        ),
      ],
    );
  },
),
    );
  }
}