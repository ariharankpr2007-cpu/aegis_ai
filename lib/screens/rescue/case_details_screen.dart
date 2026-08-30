import 'victim_reports_screen.dart';
import 'navigation_screen.dart';
import 'package:flutter/material.dart';

class CaseDetailsScreen extends StatelessWidget {
  const CaseDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF087F5B),
        foregroundColor: Colors.white,
        title: const Text("Case Details"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(
                      "Flood Assistance",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    infoTile(
                      Icons.confirmation_number,
                      "Case ID",
                      "AEG-2026-001",
                    ),

                    infoTile(
                      Icons.person,
                      "Citizen",
                      "Ariharan",
                    ),

                    infoTile(
                      Icons.phone,
                      "Phone",
                      "+91 9876543210",
                    ),

                    infoTile(
                      Icons.location_on,
                      "Location",
                      "Chennai",
                    ),

                    infoTile(
                      Icons.warning,
                      "Priority",
                      "High",
                    ),

                    infoTile(
                      Icons.schedule,
                      "Reported",
                      "10 mins ago",
                    ),

                    infoTile(
                      Icons.people,
                      "Victims",
                      "5",
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Description",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Heavy flooding has surrounded several houses. "
                      "Citizens are trapped on the first floor and "
                      "immediate rescue assistance is required.",
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 180,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 70,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const NavigationScreen(),
    ),
  );
},
                    icon: const Icon(Icons.navigation),
                    label: const Text("Navigate"),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone),
                    label: const Text("Call"),
                  ),
                ),

              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [

                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check),
                    label: const Text("Accept"),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.task_alt),
                    label: const Text("Complete"),
                  ),
                ),

              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget infoTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [

          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.green.shade100,
            child: Icon(
              icon,
              color: Colors.green,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              ],
            ),
          ),

        ],
      ),
    );
  }
}