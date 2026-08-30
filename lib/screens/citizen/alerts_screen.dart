import 'package:flutter/material.dart';

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
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          Text('Latest alerts', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('Demo alerts — Government officers will send real alerts later.'),
          SizedBox(height: 18),
          _AlertCard(
            icon: Icons.water_drop_outlined,
            color: Colors.blue,
            title: 'Heavy rain watch',
            place: 'Chennai district',
            time: 'Today · 3:20 PM',
            message: 'Avoid low-lying roads and monitor local announcements.',
          ),
          _AlertCard(
            icon: Icons.air_outlined,
            color: Colors.orange,
            title: 'Strong wind advisory',
            place: 'Coastal region',
            time: 'Today · 1:10 PM',
            message: 'Secure loose objects and avoid unnecessary travel.',
          ),
          _AlertCard(
            icon: Icons.health_and_safety_outlined,
            color: Colors.green,
            title: 'Shelter readiness update',
            place: 'District control room',
            time: 'Yesterday · 6:00 PM',
            message: 'Nearby designated shelters are prepared if evacuation is required.',
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.place,
    required this.time,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String place;
  final String time;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.13),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(place, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  Text(message),
                  const SizedBox(height: 9),
                  Text(time, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
