import 'package:flutter/material.dart';

class RescueVideoScreen extends StatelessWidget {
  const RescueVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Rescue Video"),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Rescue Team Live Video",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 90,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.videocam,
                  color: Colors.blue,
                ),
                title: const Text("Camera Status"),
                subtitle: const Text("Live Streaming"),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.timer,
                  color: Colors.orange,
                ),
                title: const Text("Duration"),
                subtitle: const Text("08:25 Minutes"),
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
                      content: Text("Playing Rescue Video"),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  "Play Video",
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
                      content: Text("Downloading Video..."),
                    ),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text("Download Video"),
              ),
            ),

          ],
        ),
      ),
    );
  }
}