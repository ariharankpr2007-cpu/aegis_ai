import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Emergency Alerts'),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('broadcast_alerts')
            .where('status', isEqualTo: 'Active')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load emergency alerts'),
            );
          }

          final alerts = snapshot.data?.docs ?? [];

          if (alerts.isEmpty) {
            return const Center(
              child: Text(
                'No active emergency alerts',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'Latest alerts',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Live alerts issued by government officers.',
              ),
              const SizedBox(height: 18),

              ...alerts.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                return _AlertCard(
                  title: data['title']?.toString() ?? 'Emergency Alert',
                  place: data['location']?.toString() ??
                      data['place']?.toString() ??
                      'Location unavailable',
                  time: _formatTime(data['createdAt']),
                  message: data['message']?.toString() ?? '',
                  priority: data['priority']?.toString() ?? 'High',
                  latitude: (data['latitude'] as num?)?.toDouble(),
                  longitude: (data['longitude'] as num?)?.toDouble(),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  static String _formatTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return 'Recently issued';
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.title,
    required this.place,
    required this.time,
    required this.message,
    required this.priority,
    required this.latitude,
    required this.longitude,
  });

  final String title;
  final String place;
  final String time;
  final String message;
  final String priority;
  final double? latitude;
  final double? longitude;

  Color get priorityColor {
    if (priority == 'High') return Colors.red;
    if (priority == 'Medium') return Colors.orange;
    return Colors.green;
  }

  IconData get alertIcon {
    if (title.toLowerCase().contains('rain')) {
      return Icons.water_drop_outlined;
    }

    if (title.toLowerCase().contains('wind')) {
      return Icons.air_outlined;
    }

    if (title.toLowerCase().contains('medical')) {
      return Icons.health_and_safety_outlined;
    }

    return Icons.warning_amber_rounded;
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exact location is unavailable for this alert'),
        ),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open Google Maps'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor:
                      priorityColor.withValues(alpha: 0.13),
                  child: Icon(
                    alertIcon,
                    color: priorityColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(message),
            const SizedBox(height: 9),
            Text(
              time,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
            if (latitude != null && longitude != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openGoogleMaps(context),
                  icon: const Icon(Icons.map),
                  label: const Text('Open location in Google Maps'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}