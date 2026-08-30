import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MissionVerificationScreen extends StatelessWidget {
  const MissionVerificationScreen({super.key});

  Future<void> _verifyMission(
  BuildContext context,
  String reportId,
  String? rescueTeamId,
) async {
  try {
    final officerId =
        FirebaseAuth.instance.currentUser!.uid;

    // 1. Officially resolve the mission
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .update({
      'status': 'Resolved',
      'verifiedAt': FieldValue.serverTimestamp(),
      'verifiedBy': officerId,
    });

    // 2. Notify the assigned rescue team
    if (rescueTeamId != null &&
        rescueTeamId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'receiverId': rescueTeamId,
        'title': 'Mission Verified',
        'body':
            'Your completed rescue mission has been officially verified and closed by the officer.',
        'type': 'mission_verified',
        'reportId': reportId,
        'isRead': false,
        'timestamp': Timestamp.now(),
      });
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mission verified and officially resolved.',
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification failed: $e',
          ),
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    // Get currently logged-in officer ID
    final officerId =
        FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text('Mission Verification'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where(
              'officerId',
              isEqualTo: officerId,
            )
            .where(
              'status',
              isEqualTo: 'Completed',
            )
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final reports = snapshot.data!.docs;

          if (reports.isEmpty) {
            return const Center(
              child: Text(
                'No missions awaiting verification.',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,

            itemBuilder: (context, index) {
              final report = reports[index];

              final data =
                  report.data() as Map<String, dynamic>;

              final disasterType =
                  data['disasterType']?.toString() ??
                      data['title']?.toString() ??
                      'Emergency';

              final description =
                  data['description']?.toString() ?? '';

              final location =
                  data['location']?.toString() ??
                      'Unknown location';

              final peopleCount =
                  data['peopleCount'] ?? 0;

              final assignedName =
                  data['assignedName']?.toString() ??
                      'Rescue Team';
                      final rescueTeamId =
    data['assignedTo']?.toString();

              return Card(
                margin:
                    const EdgeInsets.only(bottom: 16),

                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            color: Colors.orange,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              disasterType,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),

                          const Chip(
                            label: Text('Completed'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (description.isNotEmpty)
                        Text(description),

                      const SizedBox(height: 12),

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(location),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 18,
                          ),

                          const SizedBox(width: 8),

                          Text(
                            'AI detected: '
                            '$peopleCount people',
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(
                            Icons.groups_outlined,
                            size: 18,
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              'Rescue team: '
                              '$assignedName',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,

                        child: FilledButton.icon(
                          icon: const Icon(
                            Icons.verified,
                          ),

                          label: const Text(
                            'VERIFY & RESOLVE MISSION',
                          ),

                          onPressed: () =>
    _verifyMission(
  context,
  report.id,
  rescueTeamId,
),
                        ),
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