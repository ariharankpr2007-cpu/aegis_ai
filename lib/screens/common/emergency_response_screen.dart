import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../maps/live_map_screen.dart';

class EmergencyResponseScreen extends StatefulWidget {
  final String reportId;
  final String notificationId;

  const EmergencyResponseScreen({
    super.key,
    required this.reportId,
    required this.notificationId,
  });

  @override
  State<EmergencyResponseScreen> createState() =>
      _EmergencyResponseScreenState();
}

class _EmergencyResponseScreenState
    extends State<EmergencyResponseScreen> {
  bool loading = true;
  bool updating = false;

  Map<String, dynamic>? reportData;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("reports")
          .doc(widget.reportId)
          .get();

      if (!doc.exists) {
        throw Exception("Emergency report not found.");
      }

      if (!mounted) return;

      setState(() {
        reportData = doc.data();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst("Exception: ", ""),
          ),
        ),
      );
    }
  }

  Future<void> _updateResponseStatus(
    String status,
  ) async {
    if (updating) return;

    setState(() {
      updating = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection("notifications")
          .doc(widget.notificationId)
          .update({
        "responseStatus": status,
        "responseUpdatedAt": Timestamp.now(),
      });

      await FirebaseFirestore.instance
          .collection("reports")
          .doc(widget.reportId)
          .update({
        "responseStatus": status,
        "responseUpdatedAt": Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Status updated: $status",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to update status.",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          updating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (reportData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Emergency"),
        ),
        body: const Center(
          child: Text("Emergency report unavailable."),
        ),
      );
    }

    final data = reportData!;

    final disasterType =
        data["disasterType"] ?? "Emergency";

    final severity =
        data["severity"] ?? "Unknown";

    final location =
        data["location"] ?? "Unknown location";

    final assemblyPoint =
        data["assemblyPoint"] ?? location;

    final latitude =
        (data["latitude"] as num?)?.toDouble();

    final longitude =
        (data["longitude"] as num?)?.toDouble();

    final responseStatus =
        data["responseStatus"] ?? "Alert Sent";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Response"),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.red.shade200,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 55,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "EMERGENCY ALERT",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    disasterType.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _infoCard(
              Icons.priority_high,
              "Severity",
              severity.toString(),
            ),

            _infoCard(
              Icons.location_on,
              "Disaster Location",
              location.toString(),
            ),

            _infoCard(
              Icons.groups,
              "Assembly Point",
              assemblyPoint.toString(),
            ),

            if (latitude != null &&
                longitude != null)
              _infoCard(
                Icons.gps_fixed,
                "GPS Coordinates",
                "${latitude.toStringAsFixed(6)}, "
                "${longitude.toStringAsFixed(6)}",
              ),
              if (latitude != null &&
    longitude != null)
  Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    child: ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveMapScreen(
  emergencyLatitude: latitude,
  emergencyLongitude: longitude,
  emergencyTitle: disasterType.toString(),
),
            
          ),
        );
      },
      icon: const Icon(Icons.map),
      label: const Text("VIEW ON MAP"),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(
          double.infinity,
          52,
        ),
      ),
    ),
  ),

            _infoCard(
              Icons.info_outline,
              "Current Response Status",
              responseStatus.toString(),
            ),

            const SizedBox(height: 20),

            const Text(
              "Response Actions",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _actionButton(
              icon: Icons.visibility,
              title: "Acknowledge Alert",
              color: Colors.blue,
              onPressed: () {
                _updateResponseStatus(
                  "Acknowledged",
                );
              },
            ),

            _actionButton(
              icon: Icons.directions_run,
              title: "I'm En Route",
              color: Colors.orange,
              onPressed: () {
                _updateResponseStatus(
                  "En Route",
                );
              },
            ),

            _actionButton(
              icon: Icons.location_on,
              title: "I'm at Assembly Point",
              color: Colors.green,
              onPressed: () {
                _updateResponseStatus(
                  "At Assembly Point",
                );
              },
            ),

            _actionButton(
              icon: Icons.health_and_safety,
              title: "Responding",
              color: Colors.indigo,
              onPressed: () {
                _updateResponseStatus(
                  "Responding",
                );
              },
            ),

            _actionButton(
              icon: Icons.check_circle,
              title: "Complete Response",
              color: Colors.teal,
              onPressed: () {
                _updateResponseStatus(
                  "Completed",
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(top: 4),
          child: Text(value),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton.icon(
        onPressed: updating
            ? null
            : onPressed,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize:
              const Size(double.infinity, 52),
        ),
      ),
    );
  }
}