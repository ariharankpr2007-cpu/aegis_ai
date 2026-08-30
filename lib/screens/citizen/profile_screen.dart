import 'package:flutter/material.dart';
import '../common/session_actions.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Color(0xFFDCE8FF),
                  child: Icon(Icons.person, size: 58, color: Color(0xFF0B3D91)),
                ),
                SizedBox(height: 12),
                Text('Citizen User', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                SizedBox(height: 3),
                Text('Citizen account', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Personal details'),
          const _ProfileCard(
            icon: Icons.person_outline,
            title: 'Full name',
            value: 'Add your name',
          ),
          const _ProfileCard(
            icon: Icons.email_outlined,
            title: 'Email',
            value: 'Add your email',
          ),
          const _ProfileCard(
            icon: Icons.phone_outlined,
            title: 'Phone number',
            value: 'Add your phone number',
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Emergency information'),
          const _ProfileCard(
            icon: Icons.bloodtype_outlined,
            title: 'Blood group',
            value: 'Not added',
          ),
          const _ProfileCard(
            icon: Icons.medical_information_outlined,
            title: 'Medical profile',
            value: 'Add allergies and medical needs',
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile editing will be connected to the backend next.')),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit profile'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => SessionActions.confirmLogout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFDCE8FF),
          child: Icon(icon, color: const Color(0xFF0B3D91)),
        ),
        title: Text(title),
        subtitle: Text(value),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title editing will be added with backend storage.')),
        ),
      ),
    );
  }
}
