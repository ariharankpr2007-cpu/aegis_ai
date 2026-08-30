import 'package:flutter/material.dart';
import '../common/session_actions.dart';
import '../common/settings_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await SessionActions.confirmExit(context);
        if (shouldExit && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        title: const Text("AEGIS Admin"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: "Settings",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen(role: "Admin")),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () => SessionActions.confirmLogout(context),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [

          const Text(
            "Super Admin Dashboard",
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Manage authorized officers and system operations.",
          ),

          const SizedBox(height: 25),

          _adminAction(
            context,
            Icons.person_add,
            "Manage Officers",
            "Create and manage Government Officer accounts.",
            () {
              // We will connect this in the next step.
            },
          ),

          _adminAction(
            context,
            Icons.analytics_outlined,
            "System Analytics",
            "View overall disaster management statistics.",
            () {
              // We will connect this later.
            },
          ),

          _adminAction(
            context,
            Icons.settings_outlined,
            "System Settings",
            "Manage AEGIS AI system configuration.",
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen(role: "Admin")),
            ),
          ),

        ],
      ),
      ),
    );
  }

  Widget _adminAction(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),

        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEDE7F6),
          child: Icon(
            icon,
            color: const Color(0xFF6A1B9A),
          ),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Text(subtitle),

        trailing: const Icon(
          Icons.chevron_right,
        ),

        onTap: onTap,
      ),
    );
  }
}
