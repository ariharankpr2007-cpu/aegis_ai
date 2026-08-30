import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'cctv_live_screen.dart';

class LiveCctvDevicesScreen extends StatelessWidget {
  const LiveCctvDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text('Live CCTV'),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cctvDevices')
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

          final devices = snapshot.data!.docs;

          if (devices.isEmpty) {
            return const Center(
              child: Text(
                'No CCTV devices registered yet.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];

              final data =
                  device.data() as Map<String, dynamic>;

              final cameraName =
                  data['cameraName']?.toString() ??
                      'AEGIS Camera';

              final status =
                  data['status']?.toString() ?? 'offline';

              final peopleCount =
                  data['peopleCount'] ?? 0;

              final isOnline =
                  status.toLowerCase() == 'online';

              return Card(
                margin:
                    const EdgeInsets.only(bottom: 12),

                child: ListTile(
                  contentPadding:
                      const EdgeInsets.all(14),

                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: isOnline
                        ? Colors.green.shade100
                        : Colors.grey.shade300,
                    child: Icon(
                      Icons.videocam,
                      color: isOnline
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),

                  title: Text(
                    cameraName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),

                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: isOnline
                                ? Colors.green
                                : Colors.grey,
                          ),

                          const SizedBox(width: 6),

                          Text(
                            isOnline
                                ? 'ONLINE'
                                : 'OFFLINE',
                            style: TextStyle(
                              color: isOnline
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Detected people: $peopleCount',
                      ),
                    ],
                  ),

                  trailing: Icon(
                    isOnline
                        ? Icons.play_circle_fill
                        : Icons.videocam_off,
                    color: isOnline
                        ? const Color(0xFF0B3D91)
                        : Colors.grey,
                    size: 30,
                  ),

                  onTap: isOnline
    ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CctvLiveScreen(
              deviceId: device.id,
              cameraName: cameraName,
            ),
          ),
        );
      }
    : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}