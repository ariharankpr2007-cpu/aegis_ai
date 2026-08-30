import 'package:flutter/material.dart';

class VictimReportsScreen extends StatelessWidget {
  const VictimReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Victim Report"),
        backgroundColor: const Color(0xFF087F5B),
        foregroundColor: Colors.white,
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
                      "Citizen Information",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    reportTile(
                      Icons.person,
                      "Citizen",
                      "Ariharan",
                    ),

                    reportTile(
                      Icons.phone,
                      "Phone",
                      "+91 9876543210",
                    ),

                    reportTile(
                      Icons.location_on,
                      "Location",
                      "Chennai",
                    ),

                    reportTile(
                      Icons.warning,
                      "Disaster",
                      "Flood",
                    ),

                    reportTile(
                      Icons.psychology,
                      "AI Risk",
                      "High",
                    ),

                    reportTile(
                      Icons.people,
                      "Victims",
                      "5",
                    ),

                    reportTile(
                      Icons.schedule,
                      "Reported",
                      "10 Minutes Ago",
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Heavy flood water has entered the residential area. Five people are trapped inside the house and require immediate rescue assistance.",
                    ),

                    const SizedBox(height: 20),

                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.image),
                        label: const Text("View Uploaded Image"),
                      ),
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Rescue Team Assigned"),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle),
                label: const Text("Accept Rescue Mission"),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Citizen Contacted"),
                    ),
                  );
                },
                icon: const Icon(Icons.phone),
                label: const Text("Contact Citizen"),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget reportTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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