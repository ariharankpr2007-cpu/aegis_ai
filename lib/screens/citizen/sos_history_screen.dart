import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SosHistoryScreen extends StatefulWidget {
  const SosHistoryScreen({super.key});

  @override
  State<SosHistoryScreen> createState() =>
      _SosHistoryScreenState();
}

class _SosHistoryScreenState extends State<SosHistoryScreen> {
    final _supabase = Supabase.instance.client;
    RealtimeChannel? _historyChannel;
  bool _loading = true;
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _officialSosRecords = [];

  @override
void initState() {
  super.initState();
  _loadHistory();
  _listenForSosUpdates();
}
void _listenForSosUpdates() {
  _historyChannel = _supabase
      .channel('citizen-sos-history')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'emergency_alerts',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'citizen_id',
          value: 'citizen_demo',
        ),
        callback: (payload) async {
          debugPrint('SOS HISTORY UPDATED: ${payload.eventType}');

          await _loadHistory();
        },
      )
      .subscribe();
}

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();

    final records =
        prefs.getStringList('sos_history') ?? [];

    final history = <Map<String, dynamic>>[];

    for (final record in records) {
      try {
        final decoded =
            jsonDecode(record) as Map<String, dynamic>;

        history.add(decoded);
      } catch (_) {
        // Skip invalid saved records.
      }
    }
    final officialRecords = await _loadOfficialSosRecords();

    if (!mounted) return;

    setState(() {
  _history = history;
  _officialSosRecords = officialRecords;
  _loading = false;
});
  }
  Future<List<Map<String, dynamic>>> _loadOfficialSosRecords() async {
  try {
    final data = await _supabase
        .from('emergency_alerts')
        .select()
        .eq('citizen_id', 'citizen_demo')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    debugPrint('SUPABASE SOS HISTORY ERROR: $e');
    return [];
  }
}

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear SOS history?'),
        content: const Text(
          'This will permanently remove all saved SOS records from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sos_history');

    if (!mounted) return;

    setState(() {
      _history = [];
    });
  }

  String _formatTime(String value) {
    try {
      final date = DateTime.parse(value).toLocal();

      final hour =
          date.hour % 12 == 0 ? 12 : date.hour % 12;

      final minute =
          date.minute.toString().padLeft(2, '0');

      final period =
          date.hour >= 12 ? 'PM' : 'AM';

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} • '
          '$hour:$minute $period';
    } catch (_) {
      return 'Unknown time';
    }
  }

  Future<void> _openMaps(String link) async {
    final uri = Uri.parse(link);

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open Maps.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F7),
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text('SOS History'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.red,
              ),
            )
          : _history.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 70,
                          color: Colors.black38,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No SOS history yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'SOS activations will appear here.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
    padding: const EdgeInsets.all(16),
    children: [

      // =========================
      // OFFICIAL SOS STATUS
      // =========================
      if (_officialSosRecords.isNotEmpty) ...[
        const Text(
          'Official SOS Status',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        ..._officialSosRecords.map(
          (alert) {
            final status =
                alert['status']?.toString() ?? 'pending';

            final isPending = status == 'pending';
            final isAcknowledged =
                status == 'acknowledged';

            return Card(
              margin:
                  const EdgeInsets.only(bottom: 14),
              color: isPending
                  ? Colors.red.shade50
                  : isAcknowledged
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        Icon(
                          Icons.emergency,
                          color: isPending
                              ? Colors.red
                              : isAcknowledged
                                  ? Colors.orange
                                  : Colors.green,
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      _formatTime(
                        alert['created_at']
                                ?.toString() ??
                            '',
                      ),
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 20,
                        ),

                        const SizedBox(width: 6),

                        Expanded(
                          child: Text(
                            alert['location_text']
                                    ?.toString() ??
                                'Location unavailable',
                          ),
                        ),
                      ],
                    ),

                    if (alert['officer_name'] != null) ...[
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 20,
                          ),

                          const SizedBox(width: 6),

                          Expanded(
                            child: Text(
                              'Handled by: ${alert['officer_name']}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],

      // =========================
      // LOCAL DEVICE HISTORY
      // =========================
      if (_history.isNotEmpty) ...[
        const SizedBox(height: 12),

        const Text(
          'Device SOS Activity',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        ..._history.map(
  (record) {
    final location =
        record['location']?.toString() ??
            'Location unavailable';

    final time =
        record['time']?.toString() ?? '';

    final mapsLink =
        record['mapsLink']?.toString() ?? '';

    final hasContact =
        record['hasPersonalContact'] == true;

    final smsAttempted =
        record['smsAttempted'] == true;

    final mapsOpened =
        record['mapsOpened'] == true;

    final callAttempted =
        record['callAttempted'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFFFE5E5),
                  child: Icon(
                    Icons.sos,
                    color: Colors.red,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    _formatTime(time),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.red,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(location),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Icon(
                  hasContact
                      ? Icons.check_circle_outline
                      : Icons.person_off_outlined,
                  size: 18,
                  color: hasContact
                      ? Colors.green
                      : Colors.orange,
                ),

                const SizedBox(width: 7),

                Text(
                  hasContact
                      ? 'Emergency contact available'
                      : 'No personal contact saved',
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Divider(),

            const SizedBox(height: 8),

            const Text(
              'Actions taken',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionStatus(
                  icon: Icons.location_on_outlined,
                  label: 'Location detected',
                  completed:
                      record['locationDetected'] == true,
                ),

                _ActionStatus(
                  icon: Icons.sms_outlined,
                  label: 'SMS',
                  completed: smsAttempted,
                ),

                _ActionStatus(
                  icon: Icons.map_outlined,
                  label: 'Maps',
                  completed: mapsOpened,
                ),

                _ActionStatus(
                  icon: Icons.call_outlined,
                  label: 'Call 112',
                  completed: callAttempted,
                ),
              ],
            ),

            if (mapsLink.isNotEmpty) ...[
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () =>
                    _openMaps(mapsLink),
                icon: const Icon(
                  Icons.map_outlined,
                ),
                label: const Text(
                  'Open location',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  },
),
      ],
    ],
  ),
    );
  }
  @override
void dispose() {
  if (_historyChannel != null) {
    _supabase.removeChannel(_historyChannel!);
  }

  super.dispose();
}
}
class _ActionStatus extends StatelessWidget {
  const _ActionStatus({
    required this.icon,
    required this.label,
    required this.completed,
  });

  final IconData icon;
  final String label;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: completed
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed
                ? Icons.check_circle
                : icon,
            size: 16,
            color: completed
                ? Colors.green
                : Colors.grey,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: completed
                  ? Colors.green.shade700
                  : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}