import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignedCasesScreen extends StatelessWidget {
  const AssignedCasesScreen({super.key});
  Future<void> openGoogleMaps(
  double latitude,
  double longitude,
) async {

  final Uri url = Uri.parse(
    "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude",
  );

  print(url);

  final launched = await launchUrl(
    url,
    mode: LaunchMode.externalApplication,
  );

  print("Launched: $launched");
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assigned Cases"),
        backgroundColor: const Color(0xFF087F5B),
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
    .collection("reports")
    .where(
      "assignedTo",
      isEqualTo: FirebaseAuth.instance.currentUser!.uid,
    )
    .where(
      "status",
      whereIn: ["Assigned", "In Progress"],
    )
    .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No Assigned Cases",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final reports = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {

              final report =
                  reports[index].data()
                      as Map<String, dynamic>;
                                    return Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        report["title"] ?? "",
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      if ((report["imageUrl"] ?? "")
                          .toString()
                          .isNotEmpty)

                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(10),

                          child: Image.network(
                            report["imageUrl"],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                      const SizedBox(height: 10),

                      Text(
                        "📍 ${report["location"]}",
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "🚨 ${report["severity"]}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        report["description"] ?? "",
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
  child: OutlinedButton.icon(
    onPressed: () {
      print("Latitude: ${report["latitude"]}");
print("Longitude: ${report["longitude"]}");
  if (report["latitude"] != null &&
      report["longitude"] != null) {
    openGoogleMaps(
      (report["latitude"] as num).toDouble(),
      (report["longitude"] as num).toDouble(),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Location not available"),
      ),
    );
  }
},
    icon: const Icon(Icons.navigation),
    label: const Text("Navigate"),
  ),
),

const SizedBox(width: 10),

Expanded(
  child: ElevatedButton(
    onPressed: () async {

      if (report["status"] == "Assigned") {

        await FirebaseFirestore.instance
            .collection("reports")
            .doc(reports[index].id)
            .update({

          "status": "In Progress",

        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mission Accepted"),
          ),
        );

      }

      else if (report["status"] == "In Progress") {

        await FirebaseFirestore.instance
            .collection("reports")
            .doc(reports[index].id)
            .update({

          "status": "Resolved",

        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mission Completed"),
          ),
        );

      }

    },

    child: Text(

      report["status"] == "Assigned"
          ? "Accept"

      : report["status"] == "In Progress"
          ? "Complete"

      : "Completed",

    ),
  ),
),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
  