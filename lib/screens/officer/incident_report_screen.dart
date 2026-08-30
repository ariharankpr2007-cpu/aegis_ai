import 'package:flutter/material.dart';

class IncidentReportScreen extends StatelessWidget {
  const IncidentReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Incident Report"),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Incident Details",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const Icon(Icons.person,color: Colors.blue),
                title: const Text("Reported By"),
                subtitle: const Text("Ariharan"),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.warning,color: Colors.red),
                title: const Text("Disaster Type"),
                subtitle: const Text("Flood"),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on,color: Colors.green),
                title: const Text("Location"),
                subtitle: const Text("Chennai"),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time,color: Colors.orange),
                title: const Text("Reported Time"),
                subtitle: const Text("10 Minutes Ago"),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Description",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Heavy flooding has affected the residential area. "
              "Multiple families are trapped and immediate rescue "
              "assistance is required.",
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Incident Report Approved"),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  "Approve Report",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Incident Report Downloaded"),
                    ),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text("Download Report"),
              ),
            ),

          ],
        ),
      ),
    );
  }
}