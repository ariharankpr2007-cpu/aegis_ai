import 'package:flutter/material.dart';
import '../common/session_actions.dart';

class RescueProfileScreen extends StatelessWidget {
  const RescueProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Rescue Profile"),
        backgroundColor: const Color(0xFF087F5B),
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            const CircleAvatar(
              radius: 55,
              child: Icon(
                Icons.person,
                size: 60,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "John David",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Text(
              "Senior Rescue Officer",
            ),

            const SizedBox(height: 25),

            profileTile(
              Icons.badge,
              "Employee ID",
              "RES-1024",
            ),

            profileTile(
              Icons.phone,
              "Phone",
              "+91 9876543210",
            ),

            profileTile(
              Icons.email,
              "Email",
              "john@aegis.ai",
            ),

            profileTile(
              Icons.location_on,
              "Station",
              "Chennai Central",
            ),

            profileTile(
              Icons.groups,
              "Team",
              "Alpha Rescue Team",
            ),

            profileTile(
              Icons.task_alt,
              "Completed Missions",
              "248",
            ),

            profileTile(
              Icons.star,
              "Experience",
              "8 Years",
            ),

            profileTile(
              Icons.verified,
              "Status",
              "Available",
            ),

            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Profile Updated"),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text("Edit Profile"),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => SessionActions.confirmLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget profileTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(
            icon,
            color: Colors.green,
          ),
        ),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
