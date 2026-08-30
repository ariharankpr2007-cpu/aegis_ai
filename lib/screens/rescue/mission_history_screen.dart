import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MissionHistoryScreen extends StatelessWidget {
  const MissionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rescueTeamId =
        FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Mission History"),
        backgroundColor: const Color(0xFF087F5B),
        foregroundColor: Colors.white,
      ),

      body: rescueTeamId == null
          ? const Center(
              child: Text(
                "Please login again.",
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
    .collection("reports")
    .where(
      "assignedTo",
      isEqualTo: rescueTeamId,
    )
    .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Unable to load mission history.\n\n"
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 80,
                          color: Colors.grey,
                        ),

                        SizedBox(height: 15),

                        Text(
                          "No Mission History",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          "Completed missions will appear here.",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final missions =
    snapshot.data!.docs.where((doc) {
  final data =
      doc.data() as Map<String, dynamic>;

  final status =
      data["status"]?.toString() ?? "";

  return status == "Completed" ||
      status == "Resolved";
}).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: missions.length,

                  itemBuilder: (context, index) {
                    final doc = missions[index];

                    final data =
                        doc.data()
                            as Map<String, dynamic>;

                    final title =
                        data["title"] ?? "Untitled Mission";

                    final location =
                        data["location"] ?? "Unknown";

                    final disasterType =
                        data["disasterType"] ?? "Unknown";

                        final status =
    data["status"]?.toString() ?? "Completed";

final isResolved =
    status == "Resolved";

                    final severity =
                        data["severity"] ?? "Unknown";

                    final completedAt =
                        data["completedAt"];

                    String completedText =
                        "Completion time unavailable";

                    if (completedAt
                        is Timestamp) {
                      final date =
                          completedAt.toDate();

                      completedText =
                          "${date.day.toString().padLeft(2, '0')}/"
                          "${date.month.toString().padLeft(2, '0')}/"
                          "${date.year}  "
                          "${date.hour.toString().padLeft(2, '0')}:"
                          "${date.minute.toString().padLeft(2, '0')}";
                    }

                    return InkWell(
  borderRadius: BorderRadius.circular(12),

  onTap: () {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),

          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  "📍 Location : $location",
                ),

                const SizedBox(height: 8),

                Text(
                  "🌊 Type : $disasterType",
                ),

                const SizedBox(height: 8),

                Text(
                  "🚨 Severity : $severity",
                ),

                const SizedBox(height: 12),

                Text(
                  "📝 Description : "
                  "${data["description"] ?? "No description"}",
                ),

                const SizedBox(height: 12),

                Text(
                  "✓ Completed : $completedText",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  },
                    

  child: Card(
    margin: const EdgeInsets.only(
      bottom: 12,
    ),

    child: Padding(
                        padding:
                            const EdgeInsets.all(16),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            Row(
                              children: [
                                CircleAvatar(
  backgroundColor:
      isResolved
          ? Colors.green
          : Colors.orange,

  child: Icon(
    isResolved
        ? Icons.verified
        : Icons.pending_actions,
    color: Colors.white,
  ),
),

                                const SizedBox(
                                  width: 12,
                                ),

                                Expanded(
                                  child: Text(
                                    title,
                                    style:
                                        const TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            Text(
                              "📍 Location : $location",
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "🌊 Type : $disasterType",
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "🚨 Severity : $severity",
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 12),

Container(
  width: double.infinity,

  padding: const EdgeInsets.all(10),

  decoration: BoxDecoration(
    color: isResolved
        ? Colors.green.shade50
        : Colors.orange.shade50,

    borderRadius:
        BorderRadius.circular(8),
  ),

  child: Text(
    isResolved
        ? "✓ Resolved & Officer Verified"
        : "⏳ Completed\nAwaiting officer verification",

    style: TextStyle(
      color: isResolved
          ? Colors.green
          : Colors.orange,

      fontWeight:
          FontWeight.bold,
    ),
  ),
),

const SizedBox(height: 6),

Text(
  isResolved
      ? "Verified: ${data["verifiedAt"] != null ? completedText : "Time unavailable"}"
      : "Completed: $completedText",
  style: const TextStyle(
    fontSize: 13,
    color: Colors.grey,
  ),
),
                          ],
                        ),
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