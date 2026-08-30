import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../officer/report_details_screen.dart';
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

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Live Disaster Map"),
      ),

      body: FlutterMap(
         mapController: mapController,

        options: MapOptions(
  initialCenter: currentLocation,
  initialZoom: 15,
  onMapReady: () {
    mapController.move(currentLocation, 15);
  },
),

        children: [

  TileLayer(
    urlTemplate:
        'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png?api_key=stadiamaps_ecc4ea2f-d5c0-4ad1-a864-34504eddc17a',
  ),
  if (emergencyLocation != null)
  MarkerLayer(
    markers: [
      Marker(
        point: emergencyLocation!,
        width: 70,
        height: 70,
        child: Tooltip(
          message:
              widget.emergencyTitle ??
              "Emergency",
          child: const Icon(
            Icons.warning_rounded,
            color: Colors.red,
            size: 48,
          ),
        ),
      ),
    ],
  ),

  // ---------------- REPORT MARKERS ----------------
  

  StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("reports")
        .snapshots(),
    builder: (context, snapshot) {

      List<Marker> markers = [];

      // Citizen marker
      markers.add(
        Marker(
          point: currentLocation,
          width: 20,
          height: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
          ),
        ),
      );

      if (snapshot.hasData) {

        for (var doc in snapshot.data!.docs) {

          final report =
              doc.data() as Map<String, dynamic>;

          if (report["latitude"] != null &&
              report["longitude"] != null) {

            markers.add(

              Marker(
                point: LatLng(
                  (report["latitude"] as num).toDouble(),
                  (report["longitude"] as num).toDouble(),
                ),
                width: 60,
                height: 60,
                child: GestureDetector(
                  onTap: () {

                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(report["title"] ?? ""),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Text("📍 ${report["location"]}"),

                            const SizedBox(height: 8),

                            Text("🚨 ${report["severity"]}"),

                            const SizedBox(height: 8),

                            Text(
                              report["description"] ?? "",
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

  ElevatedButton.icon(
  onPressed: () {
    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailsScreen(
          report: {
            ...report,
            "id": doc.id,
          },
        ),
      ),
    );
  },
  icon: const Icon(Icons.assignment),
  label: const Text("Assign"),
),

],
                      ),
                    );

                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),

            );
          }
        }
      }

      return MarkerLayer(
        markers: markers,
      );
    },
  ),
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
     MarkerLayer(
  markers: [

    Marker(
      point: const LatLng(13.0827, 80.2707),
      width: 60,
      height: 60,
      child: Tooltip(
        message: "Government Hospital",
        child: const Icon(
          Icons.local_hospital,
          color: Colors.red,
          size: 35,
        ),
      ),
    ),

    Marker(
      point: const LatLng(13.0790, 80.2750),
      width: 60,
      height: 60,
      child: Tooltip(
        message: "Fire Station",
        child: const Icon(
          Icons.local_fire_department,
          color: Colors.orange,
          size: 35,
        ),
      ),
    ),

    Marker(
      point: const LatLng(13.0865, 80.2680),
      width: 60,
      height: 60,
      child: Tooltip(
        message: "Police Station",
        child: const Icon(
          Icons.local_police,
          color: Colors.blue,
          size: 35,
        ),
      ),
    ),

    Marker(
      point: const LatLng(13.0845, 80.2790),
      width: 60,
      height: 60,
      child: Tooltip(
        message: "Relief Shelter",
        child: const Icon(
          Icons.home,
          color: Colors.green,
          size: 35,
        ),
      ),
    ),

  ],
),
               ],
      ),
    );
  }
}