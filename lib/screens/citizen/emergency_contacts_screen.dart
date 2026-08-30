import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends State<EmergencyContactsScreen> {
      String? _personalContactName;
String? _personalContactNumber;

@override
void initState() {
  super.initState();
  _loadPersonalContact();
}

Future<void> _loadPersonalContact() async {
  final prefs = await SharedPreferences.getInstance();

  if (!mounted) return;

  setState(() {
    _personalContactName =
        prefs.getString('personal_contact_name');
    _personalContactNumber =
        prefs.getString('personal_contact_number');
  });
}

Future<void> _savePersonalContact(
  String name,
  String number,
) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(
    'personal_contact_name',
    name,
  );

  await prefs.setString(
    'personal_contact_number',
    number,
  );

  if (!mounted) return;

  setState(() {
    _personalContactName = name;
    _personalContactNumber = number;
  });
}

Future<void> _deletePersonalContact() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.remove('personal_contact_name');
  await prefs.remove('personal_contact_number');

  if (!mounted) return;

  setState(() {
    _personalContactName = null;
    _personalContactNumber = null;
  });
}

  static const _contacts = <_EmergencyContact>[
  _EmergencyContact(
    'National Emergency',
    '112',
    Icons.emergency_outlined,
    Colors.red,
  ),
  _EmergencyContact(
    'Ambulance',
    '108',
    Icons.local_hospital_outlined,
    Colors.green,
  ),
  _EmergencyContact(
    'Fire and Rescue',
    '101',
    Icons.local_fire_department_outlined,
    Colors.orange,
  ),
  _EmergencyContact(
    'Police',
    '100',
    Icons.local_police_outlined,
    Colors.indigo,
  ),
];
void _showPersonalContactDialog() {
  final nameController = TextEditingController(
    text: _personalContactName ?? '',
  );

  final numberController = TextEditingController(
    text: _personalContactNumber ?? '',
  );

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          _personalContactName == null
              ? 'Add personal contact'
              : 'Edit personal contact',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final number = numberController.text.trim();

              if (name.isEmpty || number.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter both name and phone number.',
                    ),
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);

              await _savePersonalContact(
                name,
                number,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Personal emergency contact saved.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('Call for help', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Use these numbers only in a real emergency.'),
          const SizedBox(height: 18),
          ..._contacts.map((contact) => _ContactCard(contact: contact)),
          const SizedBox(height: 10),
          Card(
  child: ListTile(
    leading: CircleAvatar(
      child: Icon(
        _personalContactName == null
            ? Icons.person_add_alt_1_outlined
            : Icons.person,
      ),
    ),
    title: Text(
      _personalContactName ?? 'Add personal contact',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: Text(
      _personalContactNumber ??
          'Add a family member or trusted person',
    ),
    trailing: _personalContactName == null
    ? const Icon(Icons.add)
    : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(
              Icons.call,
              color: Colors.green,
            ),
            onPressed: () async {
              final phone = Uri(
                scheme: 'tel',
                path: _personalContactNumber!,
              );

              try {
                await launchUrl(
                  phone,
                  mode: LaunchMode.externalApplication,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to open dialer: $e',
                      ),
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
            onPressed: _deletePersonalContact,
          ),
        ],
      ),
    onTap: _showPersonalContactDialog,
  ),
),
        ],
      ),
    );
  }
}

class _EmergencyContact {
  const _EmergencyContact(this.name, this.number, this.icon, this.color);
  final String name;
  final String number;
  final IconData icon;
  final Color color;
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});
  final _EmergencyContact contact;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: contact.color.withValues(alpha: 0.13),
          child: Icon(contact.icon, color: contact.color),
        ),
        title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(contact.number),
        trailing: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: contact.color),
          onPressed: () async {
  final shouldCall = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Call ${contact.name}?'),
        content: Text(
          'You are about to call ${contact.number}. '
          'Use emergency services only for a real emergency.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: contact.color,
            ),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Call now'),
          ),
        ],
      );
    },
  );

  if (shouldCall != true) return;

  final Uri phone = Uri(
    scheme: 'tel',
    path: contact.number,
  );

  try {
    await launchUrl(
      phone,
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open dialer: $e'),
        ),
      );
    }
  }
},
          icon: const Icon(Icons.call),
          label: const Text('Call'),
        ),
      ),
    );
  }
}
