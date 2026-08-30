import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.role});

  final String role;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationUpdatesEnabled = true;

  Color get _accentColor {
    switch (widget.role) {
      case 'Rescue':
        return const Color(0xFF087F5B);
      case 'Admin':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF0B3D91);
    }
  }

  String get _roleLabel => widget.role == 'Rescue' ? 'Rescue Team' : widget.role;

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Signed-in account';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _accentColor.withValues(alpha: 0.12),
                child: Icon(Icons.person_outline, color: _accentColor),
              ),
              title: Text('$_roleLabel account'),
              subtitle: Text(email),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: (value) => setState(() => _notificationsEnabled = value),
                  title: const Text('Emergency notifications'),
                  subtitle: const Text('Receive alerts and response updates.'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _locationUpdatesEnabled,
                  onChanged: (value) => setState(() => _locationUpdatesEnabled = value),
                  title: const Text('Location updates'),
                  subtitle: const Text('Allow AEGIS AI to use your location when needed.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About AEGIS AI'),
              subtitle: const Text('AI-powered disaster management and emergency response.'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'AEGIS AI',
                applicationVersion: '1.0.0',
                children: const [Text('AEGIS AI helps citizens and responders coordinate during emergencies.')],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
