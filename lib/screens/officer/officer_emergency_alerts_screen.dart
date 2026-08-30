import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'citizen_details_screen.dart';

class OfficerEmergencyAlertsScreen extends StatefulWidget {
  const OfficerEmergencyAlertsScreen({super.key});

  @override
  State<OfficerEmergencyAlertsScreen> createState() =>
      _OfficerEmergencyAlertsScreenState();
}

class _OfficerEmergencyAlertsScreenState
    extends State<OfficerEmergencyAlertsScreen> {
  final _supabase = Supabase.instance.client;

RealtimeChannel? _alertsChannel;

bool _loading = true;
List<Map<String, dynamic>> _alerts = [];

  @override
void initState() {
  super.initState();

  _loadAlerts();
  _listenForEmergencyAlerts();
}
Future<String> _getOfficerName() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return 'Unknown Officer';
  }

  final officerDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (officerDoc.exists) {
    return officerDoc.data()?['name'] ?? 'Unknown Officer';
  }

  return 'Unknown Officer';
}
void _listenForEmergencyAlerts() {
  _alertsChannel = _supabase
      .channel('emergency_alerts_channel')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'emergency_alerts',
        callback: (payload) {
  debugPrint(
    'Emergency alert updated: ${payload.eventType}',
  );

  _loadAlerts();

  if (payload.eventType == PostgresChangeEvent.insert &&
      mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '🚨 NEW EMERGENCY SOS RECEIVED',
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }
},
      )
      .subscribe();
}
@override
void dispose() {
  if (_alertsChannel != null) {
    _supabase.removeChannel(_alertsChannel!);
  }

  super.dispose();
}

  Future<void> _loadAlerts() async {
    try {
      setState(() => _loading = true);

      final data = await _supabase
          .from('emergency_alerts')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _alerts = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load emergency alerts: $e'),
        ),
      );
    }
  }

  Future<void> _acknowledgeAlert(int id) async {
  try {
    debugPrint('ACKNOWLEDGING SOS ID: $id');
    final officerName = await _getOfficerName();
final officerId = FirebaseAuth.instance.currentUser?.uid;
    final updatedData = await _supabase
        .from('emergency_alerts')
        .update({
  'status': 'acknowledged',
  'officer_id': officerId ?? 'unknown_officer',
  'officer_name': officerName,
  'acknowledged_at': DateTime.now().toUtc().toIso8601String(),
})
        .eq('id', id)
        .select()
        .single();

    if (!mounted) return;

    setState(() {
      final index = _alerts.indexWhere(
        (alert) => alert['id'] == id,
      );

      if (index != -1) {
        _alerts[index] =
            Map<String, dynamic>.from(updatedData);
      }
    });

    debugPrint('UPDATED SOS: $updatedData');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SOS acknowledged successfully'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    debugPrint('ACKNOWLEDGE ERROR: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to acknowledge SOS: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Future<void> _resolveAlert(int id) async {
  try {
    debugPrint('RESOLVING SOS ID: $id');

    final updatedData = await _supabase
        .from('emergency_alerts')
        .update({
          'status': 'resolved',
          'resolved_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();

    if (!mounted) return;

    setState(() {
      final index = _alerts.indexWhere(
        (alert) => alert['id'] == id,
      );

      if (index != -1) {
        _alerts[index] =
            Map<String, dynamic>.from(updatedData);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency marked as resolved'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    debugPrint('RESOLVE ERROR: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to resolve SOS: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Future<void> _openMaps(String mapsLink) async {
    final uri = Uri.parse(mapsLink);

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Emergency Alerts'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadAlerts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _alerts.isEmpty
              ? const Center(
                  child: Text(
                    'No emergency alerts',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAlerts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final alert = _alerts[index];

                      return _AlertCard(
                        alert: alert,
                        onAcknowledge: () =>
                            _acknowledgeAlert(alert['id'] as int),
                        onResolve: () =>
                            _resolveAlert(alert['id'] as int),
                        onOpenMaps: () =>
                            _openMaps(alert['maps_link'] ?? ''),
                      );
                    },
                  ),
                ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onAcknowledge,
    required this.onResolve,
    required this.onOpenMaps,
  });

  final Map<String, dynamic> alert;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;
  final VoidCallback onOpenMaps;

  String _timeAgo(String? createdAt) {
  if (createdAt == null) return 'Unknown time';

  final dateTime = DateTime.tryParse(createdAt)?.toLocal();

  if (dateTime == null) return 'Unknown time';

  final difference = DateTime.now().difference(dateTime);

  if (difference.inSeconds < 60) {
    return 'Just now';
  }

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  }

  if (difference.inHours < 24) {
    return '${difference.inHours} hr ago';
  }

  return '${difference.inDays} day ago';
}

  @override
  Widget build(BuildContext context) {
    final status = alert['status'] ?? 'pending';

    final isPending = status == 'pending';
    final isAcknowledged = status == 'acknowledged';
    final isResolved = status == 'resolved';

    return Card(
  margin: const EdgeInsets.only(bottom: 14),
  color: isPending
      ? Colors.red.shade50
      : isAcknowledged
          ? Colors.orange.shade50
          : Colors.green.shade50,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(
      color: isPending
          ? Colors.red
          : isAcknowledged
              ? Colors.orange
              : Colors.green,
      width: isPending ? 2 : 1,
    ),
  ),
  child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: isPending ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 8),
                const Expanded(
  child: Text(
    'EMERGENCY SOS',
    style: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.bold,
    ),
  ),
),

if (isPending)
  Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Text(
      'NEW',
      style: TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
  )
else
  Chip(
    label: Text(
      status.toString().toUpperCase(),
    ),
  ),
              ],
            ),

            const Divider(height: 24),

            Row(
  children: [
    Expanded(
      child: Text(
        alert['citizen_name'] ?? 'Unknown citizen',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    Text(
      _timeAgo(alert['created_at']?.toString()),
      style: const TextStyle(
        fontSize: 12,
        color: Colors.black54,
      ),
    ),
  ],
),

const SizedBox(height: 8),
if (alert['officer_name'] != null) ...[
  Row(
    children: [
      const Icon(
        Icons.person_outline,
        size: 18,
        color: Colors.blue,
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          'Handled by: ${alert['officer_name']}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  ),
  const SizedBox(height: 8),
],

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alert['location_text'] ??
                        'Location unavailable',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: onOpenMaps,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open location in Maps'),
            ),
            const SizedBox(height: 10),

OutlinedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CitizenDetailsScreen(
          citizenId: alert['citizen_id']?.toString() ?? '',
          citizenName: alert['citizen_name']?.toString() ?? '',
        ),
      ),
    );
  },
  icon: const Icon(Icons.person_outline),
  label: const Text('VIEW CITIZEN DETAILS'),
),

            const SizedBox(height: 12),

            if (isPending)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: onAcknowledge,
                  icon: const Icon(Icons.check),
                  label: const Text('ACKNOWLEDGE SOS'),
                ),
              ),

            if (isAcknowledged)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () async {
  final shouldResolve = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Resolve Emergency?'),
        content: const Text(
          'Are you sure this emergency has been handled and can be marked as resolved?',
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
              backgroundColor: Colors.green,
            ),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Mark Resolved'),
          ),
        ],
      );
    },
  );

  if (shouldResolve == true) {
    onResolve();
  }
},
                  icon: const Icon(Icons.check_circle),
                  label: const Text('MARK AS RESOLVED'),
                ),
              ),

            if (status == 'resolved')
              const Center(
                child: Text(
                  'Emergency resolved',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}