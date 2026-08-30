import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveTrackingScreen extends StatelessWidget {

  final Map<String, dynamic> report;

  const LiveTrackingScreen({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Live Rescue Tracking"),
        backgroundColor: const Color(0xff0B3D91),
        foregroundColor: Colors.white,
      ),

      body: FlutterMap(

  options: MapOptions(
    initialCenter: LatLng(
      (report["latitude"] as num).toDouble(),
      (report["longitude"] as num).toDouble(),
    ),
    initialZoom: 15,
  ),

  children: [

    TileLayer(
      urlTemplate:
          'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png?api_key=stadiamaps_ecc4ea2f-d5c0-4ad1-a864-34504eddc17a',
  ),


    MarkerLayer(
      markers: [

        Marker(
          point: LatLng(
            (report["latitude"] as num).toDouble(),
            (report["longitude"] as num).toDouble(),
          ),
          width: 60,
          height: 60,
          child: const Icon(
            Icons.warning,
            color: Colors.red,
            size: 40,
          ),
        ),

      ],
    ),
    StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection("rescueTeams")
      .where(
  "uid",
  isEqualTo: report["assignedTo"],
)
      .snapshots(),
  builder: (context, snapshot) {

    if (!snapshot.hasData ||
        snapshot.data!.docs.isEmpty) {
      return const SizedBox();
    }

    final rescue =
        snapshot.data!.docs.first.data()
            as Map<String, dynamic>;

    if (rescue["latitude"] == null ||
        rescue["longitude"] == null) {
      return const SizedBox();
    }

    return MarkerLayer(
      markers: [

        Marker(
          point: LatLng(
            (rescue["latitude"] as num).toDouble(),
            (rescue["longitude"] as num).toDouble(),
          ),
          width: 60,
          height: 60,
          child: Tooltip(
            message: rescue["name"] ?? "Rescue Team",
            child: const Icon(
              Icons.local_shipping,
              color: Colors.green,
              size: 40,
            ),
          ),
        ),

      ],
    );

  },
),
  ],

),
    );

  }

}