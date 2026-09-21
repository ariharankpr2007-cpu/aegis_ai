import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'citizen_live_viewer_screen.dart';

class CitizenLiveStreamsScreen extends StatelessWidget {
  const CitizenLiveStreamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text('Citizen Live Streams'),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('citizenLiveStreams')
            .where('status', isEqualTo: 'live')
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading citizen streams:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final streams = snapshot.data?.docs ?? [];

          if (streams.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: streams.length,
            itemBuilder: (context, index) {
              final stream = streams[index];

              final data =
                  stream.data() as Map<String, dynamic>;

              final citizenName =
                  data['citizenName']?.toString() ??
                      'Unknown Citizen';

              final address =
                  data['address']?.toString() ??
                      'Location unavailable';

              final latitude =
                  data['latitude'];

              final longitude =
                  data['longitude'];

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
                          CircleAvatar(
                            radius: 27,
                            backgroundColor:
                                Colors.red.shade100,
                            child: const Icon(
                              Icons.person,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  citizenName,
                                  style:
                                      const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Row(
                                  children: [
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration:
                                          const BoxDecoration(
                                        color: Colors.red,
                                        shape:
                                            BoxShape.circle,
                                      ),
                                    ),

                                    const SizedBox(
                                        width: 6),

                                    const Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // LOCATION
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 22,
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              address,
                              style:
                                  const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // GPS
                      if (latitude != null &&
                          longitude != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            left: 30,
                          ),
                          child: Text(
                            'GPS: ${latitude.toString()}, '
                            '${longitude.toString()}',
                            style:
                                const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // VIEW BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CitizenLiveViewerScreen(
                                  streamId: stream.id,
                                  citizenName:
                                      citizenName,
                                  address: address,
                                  latitude:
                                      latitude,
                                  longitude:
                                      longitude,
                                ),
                              ),
                            );
                          },

                          icon: const Icon(
                            Icons.play_circle_fill,
                          ),

                          label: const Text(
                            'VIEW LIVE STREAM',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(
                              0xFF0B3D91,
                            ),
                            foregroundColor:
                                Colors.white,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                            ),
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

  Widget _emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 70,
              color: Colors.grey,
            ),

            SizedBox(height: 15),

            Text(
              'No Citizen Live Streams',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'There are currently no citizens '
              'sharing a live emergency stream.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}