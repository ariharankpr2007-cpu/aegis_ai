import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MissionHistoryScreen extends StatelessWidget {
  const MissionHistoryScreen({super.key});

  String _formatTimestamp(dynamic value) {
    if (value == null) {
      return 'Not available';
    }

    if (value is Timestamp) {
      final date = value.toDate();

      return
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final officerId =
        FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text('Mission History'),
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
              isEqualTo: 'Resolved',
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
                'No resolved missions yet.',
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
                  report.data()
                      as Map<String, dynamic>;

              final disasterType =
                  data['disasterType']?.toString() ??
                      data['title']?.toString() ??
                      'Emergency';

              final location =
                  data['location']?.toString() ??
                      'Unknown location';

              final assignedName =
                  data['assignedName']?.toString() ??
                      'Rescue Team';

              final peopleCount =
                  data['peopleCount'] ?? 0;

              final verifiedAt =
                  _formatTimestamp(
                data['verifiedAt'],
              );

              return Card(
                margin:
                    const EdgeInsets.only(bottom: 14),

                child: Padding(
                  padding:
                      const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Row(
                        children: [

                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
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
                            avatar: Icon(
                              Icons.verified,
                              size: 18,
                              color: Colors.green,
                            ),
                            label: Text(
                              'Resolved',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
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
                            Icons.groups_outlined,
                            size: 18,
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              'Rescue Team: $assignedName',
                            ),
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
                            Icons.access_time,
                            size: 18,
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              'Verified: $verifiedAt',
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