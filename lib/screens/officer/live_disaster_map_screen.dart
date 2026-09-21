import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'report_details_screen.dart';

class LiveDisasterMapScreen extends StatefulWidget {
  LiveDisasterMapScreen({super.key});

  @override
  State<LiveDisasterMapScreen> createState() =>
      _LiveDisasterMapScreenState();
}

class _LiveDisasterMapScreenState extends State<LiveDisasterMapScreen> {
  final MapController _mapController = MapController();

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_rounded,
            color: color,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    FloatingActionButton(
      heroTag: 'refreshMap',
      mini: true,
      onPressed: () {
        setState(() {});
      },
      child: const Icon(Icons.refresh),
    ),
    const SizedBox(height: 10),
    FloatingActionButton(
      heroTag: 'mapHelpButton',
      tooltip: 'Map colour guide',
      child: const Icon(Icons.info_outline),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Map Colour Guide',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLegendItem(
                    color: Colors.blue,
                    label: 'Pending Assignment',
                    description: 'Report is waiting for a rescue team.',
                  ),
                  _buildLegendItem(
                    color: Colors.green,
                    label: 'Assigned',
                    description: 'A rescue team has been assigned.',
                  ),
                  _buildLegendItem(
                    color: Colors.orange,
                    label: 'In Progress',
                    description: 'The rescue team is handling the report.',
                  ),
                  _buildLegendItem(
                    color: Colors.grey,
                    label: 'Other Status',
                    description: 'The report has another status.',
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
    const SizedBox(height: 12),
    FloatingActionButton(
      heroTag: 'mapCenterButton',
      tooltip: 'Center map',
      child: const Icon(Icons.my_location),
      onPressed: () {
        _mapController.move(
          const LatLng(13.0827, 80.2707),
          11,
        );
      },
    ),
  ],
),
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Live Disaster Map'),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
       stream: FirebaseFirestore.instance
    .collection('reports')
    .where(
      'status',
      whereIn: [
        'Pending Assignment',
        'Assigned',
        'In Progress',
      ],
    )
    .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final markers = <Marker>[];

          for (final doc in snapshot.data?.docs ?? []) {
  final data = doc.data() as Map<String, dynamic>;

  final reportData = {
    ...data,
    "id": doc.id,
  };

  final latitude = data['latitude'];
  final longitude = data['longitude'];

  if (latitude is! num || longitude is! num) {
    continue;
  }

  final lat = latitude.toDouble();
  final lng = longitude.toDouble();

  if (!lat.isFinite ||
      !lng.isFinite ||
      lat < -90 ||
      lat > 90 ||
      lng < -180 ||
      lng > 180) {
    continue;
  }

  final status = data['status']?.toString() ?? '';

  Color markerColor;

  if (status == 'Pending Assignment') {
    markerColor = Colors.blue;
  } else if (status == 'Assigned') {
    markerColor = Colors.green;
  } else if (status == 'In Progress') {
    markerColor = Colors.orange;
  } else {
    markerColor = Colors.grey;
  }

  markers.add(
    Marker(
      point: LatLng(lat, lng),
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: () {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['disasterType']?.toString() ?? 'Unknown Disaster',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Status: ${data['status']?.toString() ?? 'Unknown'}',
              style: TextStyle(
                color: markerColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    icon: const Icon(Icons.open_in_new),
    label: const Text('View Full Report'),
    onPressed: () {
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportDetailsScreen(
            report: reportData,
          ),
        ),
      );
    },
  ),
),
          ],
        ),
      );
    },
  );
},
        child: Icon(
          Icons.warning_rounded,
          color: markerColor,
          size: 38,
        ),
      ),
    ),
  );
}

          return Stack(
  children: [
    FlutterMap(
      mapController: _mapController,
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
    ),
    Positioned(
      top: 15,
      right: 15,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            _buildMapLegendItem(
              color: Colors.blue,
              label: 'Pending Assignment',
            ),
            _buildMapLegendItem(
              color: Colors.green,
              label: 'Assigned',
            ),
            _buildMapLegendItem(
              color: Colors.orange,
              label: 'In Progress',
            ),
            _buildMapLegendItem(
              color: Colors.grey,
              label: 'Other Status',
            ),
          ],
        ),
      ),
    ),
  ],
);
            
        },
      ),
    );
  }
  Widget _buildMapLegendItem({
  required Color color,
  required String label,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.circle,
          color: color,
          size: 12,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
}