import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RescueTeamDashboard extends StatelessWidget {
  final String teamId;

  const RescueTeamDashboard({
    super.key,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text('Rescue Team Dashboard'),
        backgroundColor: const Color(0xFF087F5B),
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('assignedTo', isEqualTo: teamId)
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
                'No emergencies assigned currently.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,

            itemBuilder: (context, index) {
              final doc = reports[index];

              final data =
                  doc.data() as Map<String, dynamic>;

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
                            Icons.warning_rounded,
                            color: Colors.red,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              data['disasterType']
                                      ?.toString() ??
                                  'Emergency',
                              style:
                                  const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),

                          Chip(
                            label: Text(
                              data['status']
                                      ?.toString() ??
                                  'Assigned',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        data['description']
                                ?.toString() ??
                            '',
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [

                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                          ),

                          const SizedBox(width: 6),

                          Expanded(
                            child: Text(
                              data['location']
                                      ?.toString() ??
                                  'Unknown location',
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

                          const SizedBox(width: 6),

                          Text(
                            'AI detected: '
                            '${data['peopleCount'] ?? 0} people',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,

                        child: FilledButton(
                          onPressed: () {
                            // Details screen next
                          },

                          child: const Text(
                            'VIEW EMERGENCY',
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