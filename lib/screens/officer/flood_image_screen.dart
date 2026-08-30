import 'package:flutter/material.dart';

class FloodImageScreen extends StatelessWidget {
  const FloodImageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Flood Evidence"),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Citizen Uploaded Evidence",
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.image,
                  size: 100,
                  color: Colors.blue,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on,color: Colors.red),
                title: const Text("Location"),
                subtitle: const Text("Chennai"),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule,color: Colors.orange),
                title: const Text("Uploaded"),
                subtitle: const Text("10 Minutes Ago"),
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
                      content: Text("Downloading Evidence..."),
                    ),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text(
                  "Download Evidence",
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
                      content: Text("Evidence Verified"),
                    ),
                  );
                },
                icon: const Icon(Icons.verified),
                label: const Text("Verify Evidence"),
              ),
            ),

          ],
        ),
      ),
    );
  }
}