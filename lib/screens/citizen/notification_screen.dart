import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [

          notificationCard(
            Icons.warning,
            Colors.red,
            "Flood Alert",
            "Heavy rainfall expected in Chennai.",
            "10 mins ago",
          ),

          notificationCard(
            Icons.campaign,
            Colors.orange,
            "Government Alert",
            "Move to the nearest shelter immediately.",
            "20 mins ago",
          ),

          notificationCard(
            Icons.local_hospital,
            Colors.green,
            "Medical Camp",
            "Medical assistance available nearby.",
            "40 mins ago",
          ),

          notificationCard(
            Icons.groups,
            Colors.blue,
            "Rescue Team",
            "Rescue team has reached your area.",
            "1 hour ago",
          ),

          notificationCard(
            Icons.cloud,
            Colors.indigo,
            "Weather Update",
            "Cyclone warning issued for coastal districts.",
            "2 hours ago",
          ),

        ],
      ),
    );
  }

  Widget notificationCard(
    IconData icon,
    Color color,
    String title,
    String message,
    String time,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon,color: color),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Text(message),

        trailing: Text(
          time,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}