import 'package:flutter/material.dart';

class MedicalProfileScreen extends StatefulWidget {
  const MedicalProfileScreen({super.key});

  @override
  State<MedicalProfileScreen> createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends State<MedicalProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _allergies = TextEditingController();
  final _conditions = TextEditingController();
  String _bloodGroup = 'Not specified';
  bool _shareDuringSos = true;

  @override
  void dispose() {
    _allergies.dispose();
    _conditions.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medical profile saved locally for this demo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Medical Profile'),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Card(
              color: Color(0xFFFFF3F3),
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(child: Text('Keep this information accurate. It can help responders during an SOS.')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              value: _bloodGroup,
              decoration: const InputDecoration(
                labelText: 'Blood group',
                prefixIcon: Icon(Icons.bloodtype_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                'Not specified', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
              ].map((group) => DropdownMenuItem(value: group, child: Text(group))).toList(),
              onChanged: (value) => setState(() => _bloodGroup = value ?? _bloodGroup),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _allergies,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Allergies',
                hintText: 'Example: Penicillin, peanuts',
                prefixIcon: Icon(Icons.warning_amber_outlined),
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _conditions,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Medical conditions or medicines',
                hintText: 'Example: Asthma; carries inhaler',
                prefixIcon: Icon(Icons.medical_information_outlined),
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Share during SOS'),
              subtitle: const Text('Allow verified responders to view this profile during an emergency.'),
              value: _shareDuringSos,
              onChanged: (value) => setState(() => _shareDuringSos = value),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save medical profile'),
            ),
          ],
        ),
      ),
    );
  }
}
