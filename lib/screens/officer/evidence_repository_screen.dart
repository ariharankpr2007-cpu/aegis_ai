import 'package:flutter/material.dart';
import 'flood_image_screen.dart';
import 'rescue_video_screen.dart';
import 'incident_report_screen.dart';

class EvidenceRepositoryScreen extends StatelessWidget {
  const EvidenceRepositoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Evidence Repository"),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            Card(
              child: ListTile(
                onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const FloodImageScreen(),
    ),
  );
},
                leading: const CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(Icons.image,color: Colors.white),
                ),
                title: const Text("Flood Image"),
                subtitle: const Text("Uploaded by Citizen"),
                trailing: const Icon(Icons.visibility),
              ),
            ),

            const SizedBox(height:10),

            Card(
              child: ListTile(
                onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const RescueVideoScreen(),
    ),
  );
},
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.videocam,color: Colors.white),
                ),
                title: const Text("Rescue Video"),
                subtitle: const Text("Live Stream Evidence"),
                trailing: const Icon(Icons.play_arrow),
              ),
            ),

            const SizedBox(height:10),

            Card(
              child: ListTile(
                onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const IncidentReportScreen(),
    ),
  );
},
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.description,color: Colors.white),
                ),
                title: const Text("Incident Report"),
                subtitle: const Text("Citizen Submitted Report"),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Evidence Repository Refreshed"),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text(
                  "Refresh Evidence",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 15),

          ],
        ),
      ),
    );
  }
}