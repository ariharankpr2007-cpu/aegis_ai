import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'live_tracking_screen.dart';

class ReportHistoryScreen extends StatelessWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
print("Current User UID: ${user?.uid}");
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Reports"),
        backgroundColor: const Color(0xff0B3D91),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
    .collection("reports")
    .where("reportedBy", isEqualTo: user?.uid)
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
                "No reports found.",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final reports = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report =
                  reports[index].data() as Map<String, dynamic>;
              print("Report UID: ${report["reportedBy"]}");

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const Icon(
                    Icons.report,
                    color: Colors.red,
                  ),
                  title: Text(report["title"] ?? ""),
                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

  Text(report["location"] ?? ""),

  const SizedBox(height: 4),

  Text(
  "Status : ${report["status"] ?? "Pending"}",
  style: TextStyle(
    fontWeight: FontWeight.bold,
    color: report["status"] == "Resolved"
        ? Colors.green
        : report["status"] == "In Progress"
            ? Colors.orange
            : report["status"] == "Assigned"
                ? Colors.blue
                : Colors.red,
  ),
),
  if (report["assignedName"] != null)
    Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        "🚑 Rescue Team : ${report["assignedName"]}",
      ),
    ),

],
                  ),
                  trailing: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [

    Text(
      report["severity"] ?? "",
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),

    if (report["status"] == "In Progress")
      TextButton(
        onPressed: () {

  Navigator.push(

    context,

    MaterialPageRoute(

      builder: (_) => LiveTrackingScreen(
        report: report,
      ),

    ),

  );

},
        child: const Text("Track"),
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