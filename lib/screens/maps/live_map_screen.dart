import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../officer/report_details_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
final MapController mapController = MapController();

class LiveMapScreen extends StatefulWidget {
  final double? emergencyLatitude;
  final double? emergencyLongitude;
  final String? emergencyTitle;

  const LiveMapScreen({
    super.key,
    this.emergencyLatitude,
    this.emergencyLongitude,
    this.emergencyTitle,
  });

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {

    List<Map<String, dynamic>> _sosAlerts = [];
  RealtimeChannel? _sosChannel;

  LatLng currentLocation =
    const LatLng(13.0827, 80.2707);

LatLng? emergencyLocation;

  @override
void initState() {
  super.initState();

  if (widget.emergencyLatitude != null &&
      widget.emergencyLongitude != null) {
    emergencyLocation = LatLng(
      widget.emergencyLatitude!,
      widget.emergencyLongitude!,
    );

    currentLocation = emergencyLocation!;
  }

    getLocation();
  _loadSosAlerts();

  _sosChannel = Supabase.instance.client
      .channel('live-sos-map')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'emergency_alerts',
        callback: (payload) {
          _loadSosAlerts();
        },
      )
      .subscribe();
}

  Future<void> getLocation() async {

    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) return;

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    Position position =
        await Geolocator.getCurrentPosition();

    setState(() {

      currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );
       mapController.move(currentLocation, 15);
    });
  }

    Future<void> _loadSosAlerts() async {
    try {
      final data = await Supabase.instance.client
          .from('emergency_alerts')
          .select(
            'id, citizen_name, location_text, maps_link, status, created_at',
          )
          .inFilter('status', ['pending', 'acknowledged'])
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _sosAlerts = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint('SOS MAP ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Live Disaster Map"),
      ),

      body: FlutterMap(
         mapController: mapController,

        options: MapOptions(
  initialCenter: _sosAlerts.isNotEmpty
    ? LatLng(
        double.parse(
          Uri.parse(
            _sosAlerts.first['maps_link'],
          ).queryParameters['query']!.split(',')[0],
        ),
        double.parse(
          Uri.parse(
            _sosAlerts.first['maps_link'],
          ).queryParameters['query']!.split(',')[1],
        ),
      )
    : currentLocation,
initialZoom: 12,
  onMapReady: () {
    mapController.move(currentLocation, 15);
  },
),

        children: [

  TileLayer(
    urlTemplate:
        'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png?api_key=stadiamaps_ecc4ea2f-d5c0-4ad1-a864-34504eddc17a',
  ),

  // ---------------- REPORT MARKERS ----------------

const SizedBox(),
  // ---------------- ASSIGNED RESCUE TEAM MARKERS ----------------

StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection("reports")
      .where("status", whereIn: ["Assigned", "In Progress"])
      .snapshots(),
  builder: (context, reportSnapshot) {

    if (!reportSnapshot.hasData) {
      return const SizedBox();
    }

    final reports = reportSnapshot.data!.docs;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("rescueTeams")
          .where("isApproved", isEqualTo: true)
          .snapshots(),
      builder: (context, rescueSnapshot) {

        if (!rescueSnapshot.hasData) {
          return const SizedBox();
        }

        final rescueTeams = rescueSnapshot.data!.docs;
        final List<Marker> rescueMarkers = [];

        for (final reportDoc in reports) {

          final report =
              reportDoc.data() as Map<String, dynamic>;

          final assignedTo = report["assignedTo"];

          if (assignedTo == null ||
              assignedTo.toString().isEmpty) {
            continue;
          }

          for (final rescueDoc in rescueTeams) {

            if (rescueDoc.id != assignedTo) {
              continue;
            }

            final rescue =
                rescueDoc.data() as Map<String, dynamic>;

            if (rescue["latitude"] == null ||
                rescue["longitude"] == null) {
              continue;
            }

            final rescueLocation = LatLng(
              (rescue["latitude"] as num).toDouble(),
              (rescue["longitude"] as num).toDouble(),
            );

            rescueMarkers.add(
              Marker(
                point: rescueLocation,
                width: 65,
                height: 65,
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(
                          rescue["name"] ??
                              "Rescue Team",
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "🚑 Assigned Rescue Team",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "Emergency: "
                              "${report["title"] ?? ""}",
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Status: "
                              "${report["status"] ?? ""}",
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Location: "
                              "${report["location"] ?? ""}",
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Team: "
                              "${rescue["name"] ?? "Rescue Team"}",
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Close"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            );

            break;
          }
        }

        return MarkerLayer(
          markers: rescueMarkers,
        );
      },
    );
  },
),


// ---------------- SOS ALERT MARKERS ----------------

if (_sosAlerts.isNotEmpty)
  MarkerLayer(
    markers: _sosAlerts
        .map((alert) {
          final mapsLink = alert['maps_link']?.toString() ?? '';
          final uri = Uri.tryParse(mapsLink);
          final query = uri?.queryParameters['query'];

          if (query == null || !query.contains(',')) {
            return null;
          }

          final coordinates = query.split(',');

          if (coordinates.length != 2) {
            return null;
          }

          final latitude = double.tryParse(coordinates[0]);
          final longitude = double.tryParse(coordinates[1]);

          if (latitude == null ||
              longitude == null ||
              !latitude.isFinite ||
              !longitude.isFinite) {
            return null;
          }

          final status = alert['status']?.toString() ?? 'pending';

          final markerColor = status == 'acknowledged'
              ? Colors.orange
              : Colors.purple;

          return Marker(
            point: LatLng(latitude, longitude),
            width: 90,
            height: 90,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Emergency SOS'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Citizen: ${alert['citizen_name'] ?? 'Unknown'}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Location: ${alert['location_text'] ?? 'Address unavailable'}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Status: ${alert['status'] ?? 'pending'}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coordinates: $latitude, $longitude',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Time: ${alert['created_at'] ?? 'Unknown'}',
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.sos,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          );
        })
        .whereType<Marker>()
        .toList(),
  ),
               ],
      ),
    );
    }

  @override
  void dispose() {
    if (_sosChannel != null) {
      Supabase.instance.client.removeChannel(_sosChannel!);
    }

    super.dispose();
  }
}