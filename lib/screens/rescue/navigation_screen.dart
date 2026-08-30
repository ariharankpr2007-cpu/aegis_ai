import 'package:flutter/material.dart';

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Navigation"),
        backgroundColor: const Color(0xFF087F5B),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.map,
                  size: 100,
                  color: Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text("Victim Location"),
                subtitle: const Text("Chennai, Tamil Nadu"),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.route),
                title: const Text("Distance"),
                subtitle: const Text("2.4 km"),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.timer),
                title: const Text("Estimated Time"),
                subtitle: const Text("8 Minutes"),
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
                      content: Text(
                        "Google Maps will be connected later.",
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.navigation),
                label: const Text(
                  "Start Navigation",
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