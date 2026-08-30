import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class CitizenDetailsScreen extends StatefulWidget {
  final String citizenId;
  final String citizenName;

  const CitizenDetailsScreen({
    super.key,
    required this.citizenId,
    required this.citizenName,
  });

  @override
  State<CitizenDetailsScreen> createState() =>
      _CitizenDetailsScreenState();
}

class _CitizenDetailsScreenState
    extends State<CitizenDetailsScreen> {
  bool _loading = true;
  Map<String, dynamic>? _citizen;

  @override
  void initState() {
    super.initState();
    _loadCitizenDetails();
  }

  Future<void> _loadCitizenDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.citizenId)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        setState(() {
          _citizen = doc.data();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('CITIZEN DETAILS ERROR: $e');

      if (!mounted) return;

      setState(() => _loading = false);
    }
  }

  Future<void> _callPhone(String phone) async {
    if (phone.isEmpty) return;

    final uri = Uri.parse('tel:$phone');

    final opened = await launchUrl(uri);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open phone dialer'),
        ),
      );
    }
  }

  Future<void> _openLocation() async {
    if (_citizen == null) return;

    final latitude = _citizen!['latitude'];
    final longitude = _citizen!['longitude'];

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Citizen location unavailable'),
        ),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final citizen = _citizen;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Citizen Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : citizen == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Citizen details not found.\n\n'
                      'Citizen ID: ${widget.citizenId}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(
                          Icons.person,
                          size: 45,
                          color: Colors.blue.shade700,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        citizen['name']?.toString() ??
                            widget.citizenName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        'Citizen',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.phone),
                              title: const Text('Phone'),
                              subtitle: Text(
                                citizen['phone']?.toString() ??
                                    'Not available',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.call),
                                onPressed: () => _callPhone(
                                  citizen['phone']?.toString() ?? '',
                                ),
                              ),
                            ),

                            const Divider(height: 1),

                            ListTile(
                              leading: const Icon(Icons.email_outlined),
                              title: const Text('Email'),
                              subtitle: Text(
                                citizen['email']?.toString() ??
                                    'Not available',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _openLocation,
                          icon: const Icon(Icons.location_on),
                          label: const Text(
                            'OPEN CURRENT LOCATION',
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (citizen['locationAccuracy'] != null)
                        Text(
                          'Location accuracy: '
                          '${citizen['locationAccuracy']} meters',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}