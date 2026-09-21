import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'sos_history_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'bottom_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/sms_fallback_service.dart';

class SosScreen extends StatefulWidget {
  final VoidCallback? onCancel;

  const SosScreen({
    super.key,
    this.onCancel,
  });

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  bool _sending = false;
  String? _sosStatus;
  String? _officerName;
  Timer? _statusTimer;
  int _countdown = 0;
  String _status = '';
  Future<bool> _startSosCountdown() async {
  setState(() {
    _countdown = 5;
  });

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> runCountdown() async {
            for (int i = 5; i > 0; i--) {
              if (!mounted) return;

              setDialogState(() {
                _countdown = i;
              });

              await Future<void>.delayed(
                const Duration(seconds: 1),
              );
            }

            if (Navigator.of(dialogContext).canPop()) {
              Navigator.pop(dialogContext, true);
            }
          }

          if (_countdown == 5) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              runCountdown();
            });
          }

          return AlertDialog(
            icon: const Icon(
              Icons.sos,
              color: Colors.red,
              size: 50,
            ),
            title: const Text(
              'SOS ACTIVATING',
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_countdown',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'SOS will activate automatically.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
  if (Navigator.of(dialogContext).canPop()) {
    Navigator.of(dialogContext).pop(false);
  }

  if (mounted) {
    setState(() {
      _countdown = 0;
      _sending = false;
      _status = '';
    });
  }
},
child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    },
  );

  setState(() {
    _countdown = 0;
  });

  return confirmed == true;
}
Future<String> _saveSosHistory({
  required String location,
  required bool hasPersonalContact,
  required String mapsLink,
}) async {
  final prefs = await SharedPreferences.getInstance();

  final existing =
      prefs.getStringList('sos_history') ?? [];

  final id = DateTime.now()
      .microsecondsSinceEpoch
      .toString();

  final record = {
    'id': id,
    'time': DateTime.now().toIso8601String(),
    'location': location,
    'hasPersonalContact': hasPersonalContact,
    'mapsLink': mapsLink,

    // SOS action tracking
    'locationDetected': true,
    'smsAttempted': false,
    'mapsOpened': false,
    'callAttempted': false,
  };

  existing.insert(0, jsonEncode(record));

  // Keep only the latest 10 records.
  if (existing.length > 10) {
    existing.removeRange(10, existing.length);
  }

  await prefs.setStringList(
    'sos_history',
    existing,
  );

  return id;
}

Future<void> _updateSosHistory(
  String id, {
  bool? smsAttempted,
  bool? mapsOpened,
  bool? callAttempted,
}) async {
  final prefs = await SharedPreferences.getInstance();

  final existing =
      prefs.getStringList('sos_history') ?? [];

  final updated = <String>[];

  for (final item in existing) {
    try {
      final record =
          jsonDecode(item) as Map<String, dynamic>;

      if (record['id']?.toString() == id) {
        if (smsAttempted != null) {
          record['smsAttempted'] = smsAttempted;
        }

        if (mapsOpened != null) {
          record['mapsOpened'] = mapsOpened;
        }

        if (callAttempted != null) {
          record['callAttempted'] = callAttempted;
        }
      }

      updated.add(jsonEncode(record));
    } catch (_) {
      // Keep invalid records unchanged.
      updated.add(item);
    }
  }

  await prefs.setStringList(
    'sos_history',
    updated,
  );
}
Future<Map<String, dynamic>?> _getMedicalProfile() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return null;

  final snapshot = await FirebaseFirestore.instance
      .collection('medical_profiles')
      .doc(user.uid)
      .get();

  if (!snapshot.exists) return null;

  final data = snapshot.data();

  if (data == null || data['shareDuringSos'] != true) {
    return null;
  }

  return data;
}
Future<void> _sendSosToOfficer({
  required String locationText,
  required String mapsLink,
  required double latitude,
  required double longitude,
  Map<String, dynamic>? medicalProfile,
}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    await Supabase.instance.client
        .from('emergency_alerts')
        .insert({
      'citizen_id': user.uid,
      'citizen_name': 'AEGIS Citizen',
      'location_text': locationText,
      'latitude': latitude,
      'longitude': longitude,
      'maps_link': mapsLink,
      'status': 'pending',

      // Medical details are included only when sharing is enabled.
      'blood_group': medicalProfile?['bloodGroup'],
      'allergies': medicalProfile?['allergies'],
      'medical_conditions': medicalProfile?['conditions'],
      'medical_shared': medicalProfile != null,
    });

    debugPrint('SOS SUCCESSFULLY SENT TO SUPABASE');
  } catch (e) {
    debugPrint('SUPABASE SOS ERROR: $e');
    rethrow;
  }
}
Future<Map<String, dynamic>?> _getSosStatus() async {
  try {
    final data = await Supabase.instance.client
        .from('emergency_alerts')
        .select('status, officer_id, officer_name, acknowledged_at')
        .eq(
  'citizen_id',
  FirebaseAuth.instance.currentUser!.uid,
)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;

    return Map<String, dynamic>.from(data);
  } catch (e) {
    debugPrint('STATUS CHECK ERROR: $e');
    return null;
  }
}
Future<bool> _hasActiveSos() async {
  final data = await Supabase.instance.client
      .from('emergency_alerts')
      .select('id')
      .eq(
  'citizen_id',
  FirebaseAuth.instance.currentUser!.uid,
)
      .inFilter('status', ['pending', 'acknowledged']);

  return data.isNotEmpty;
}

  Future<void> _sendSos() async {
    final hasActiveSos = await _hasActiveSos();

if (hasActiveSos) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'You already have an active SOS. Please wait for it to be resolved.',
      ),
    ),
  );

  return;
}
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.red,
        size: 46,
      ),
      title: const Text('Activate SOS?'),
      content: const Text(
        'Use SOS only during a real emergency. '
        'Your current location will be obtained before continuing.',
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
          child: const Text('Activate SOS'),
        ),
      ],
    ),
  );

  if (confirmed != true || !mounted) return;

  final countdownCompleted = await _startSosCountdown();

if (!countdownCompleted || !mounted) return;

  setState(() {
  _sending = true;
  _status = 'Getting your live location...';
});

  try {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location services are turned off.');
    }

    var permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. '
        'Please enable it in Settings.',
      );
    }
    if (mounted) {
  setState(() {
    _status = 'Locating you accurately...';
  });
}

    final position =
        await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    final placemarks = await placemarkFromCoordinates(
  position.latitude,
  position.longitude,
);

String locationText = 'Current location detected';

if (placemarks.isNotEmpty) {
  final place = placemarks.first;

  final parts = <String>[
  if (place.name != null &&
      place.name!.isNotEmpty)
    place.name!,

  if (place.subLocality != null &&
      place.subLocality!.isNotEmpty &&
      place.subLocality != place.name)
    place.subLocality!,

  if (place.locality != null &&
      place.locality!.isNotEmpty &&
      place.locality != place.name &&
      place.locality != place.subLocality)
    place.locality!,

  if (place.administrativeArea != null &&
      place.administrativeArea!.isNotEmpty)
    place.administrativeArea!,

  if (place.country != null &&
      place.country!.isNotEmpty)
    place.country!,
];

locationText = parts.join(', ');
}
final prefs = await SharedPreferences.getInstance();

final personalName =
    prefs.getString('personal_contact_name');

final personalNumber =
    prefs.getString('personal_contact_number');

final mapsLink =
    'https://www.google.com/maps/search/?api=1'
    '&query=${position.latitude},${position.longitude}';
    final medicalProfile = await _getMedicalProfile();

try {
  await _sendSosToOfficer(
    locationText: locationText,
    mapsLink: mapsLink,
    latitude: position.latitude,
    longitude: position.longitude,
    medicalProfile: medicalProfile,
  );
} catch (e) {
  debugPrint('Internet SOS failed: $e');

  // Internet failed → try cellular SMS fallback.
  if (personalNumber != null &&
      personalNumber.isNotEmpty) {
    final smsSuccess =
        await SmsFallbackService.sendEmergencySms(
      phoneNumber: personalNumber,
      emergencyType: 'AEGIS EMERGENCY SOS',
      latitude: position.latitude,
      longitude: position.longitude,
      victims: 1,
    );

    debugPrint(
      smsSuccess
          ? 'SMS FALLBACK SUCCESS'
          : 'SMS FALLBACK FAILED',
    );
  } else {
    debugPrint(
      'No personal emergency contact number available.',
    );
  }
}
if (!mounted) return;

setState(() {
  _sosStatus = 'pending';
});
  
final sosHistoryId = await _saveSosHistory(
  location: locationText,
  hasPersonalContact:
      personalNumber != null &&
      personalNumber.isNotEmpty,
  mapsLink: mapsLink,
);

final sosMessage =
    '🚨 EMERGENCY SOS!\n\n'
    'I need immediate help.\n\n'
    'My current location: $locationText\n\n'
    'Exact location: $mapsLink';

    if (!mounted) return;

    setState(() {
  _sending = false;
  _status = 'Location detected';
});

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.location_on,
          color: Colors.red,
          size: 46,
        ),
        title: const Text('SOS location ready'),
        content: Text(
  'Your current location:\n\n'
  '$locationText\n\n'
  'You can open the exact location in Maps or call emergency services.',
),
        actions: [
  TextButton(
    onPressed: () {
      Navigator.pop(dialogContext);
    },
    child: const Text('Cancel'),
  ),

  TextButton.icon(
    onPressed: () async {
      final mapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1'
        '&query=${position.latitude},${position.longitude}',
      );

      final opened = await launchUrl(
  mapsUrl,
  mode: LaunchMode.externalApplication,
);

if (opened) {
  await _updateSosHistory(
    sosHistoryId,
    mapsOpened: true,
  );
}
    },
    icon: const Icon(Icons.map_outlined),
    label: const Text('Maps'),
  ),

  if (personalNumber != null &&
      personalNumber.isNotEmpty)
    TextButton.icon(
      onPressed: () async {
        final smsUri = Uri(
          scheme: 'sms',
          path: personalNumber,
          queryParameters: {
            'body': sosMessage,
          },
        );

        try {
          final opened = await launchUrl(
  smsUri,
  mode: LaunchMode.externalApplication,
);

if (opened) {
  await _updateSosHistory(
    sosHistoryId,
    smsAttempted: true,
  );
}
        } catch (e) {
          if (dialogContext.mounted) {
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(
                content: Text('Unable to open SMS app: $e'),
              ),
            );
          }
        }
      },
      icon: const Icon(Icons.sms_outlined),
      label: Text(
        personalName == null
            ? 'Send SMS'
            : 'SMS $personalName',
      ),
    ),

  FilledButton.icon(
    style: FilledButton.styleFrom(
      backgroundColor: Colors.red,
    ),
    onPressed: () async {
      final phone = Uri(
        scheme: 'tel',
        path: '112',
      );

      try {
        final opened = await launchUrl(
  phone,
  mode: LaunchMode.externalApplication,
);

if (opened) {
  await _updateSosHistory(
    sosHistoryId,
    callAttempted: true,
  );
}
      } catch (e) {
        if (dialogContext.mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            SnackBar(
              content: Text('Unable to open dialer: $e'),
            ),
          );
        }
      }
    },
    icon: const Icon(Icons.call),
    label: const Text('Call 112'),
  ),
],
      ),
    );
  } catch (e) {
    if (!mounted) return;

    setState(() => _sending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('SOS failed: $e'),
      ),
    );
  }
}
@override
void initState() {
  super.initState();

  _loadSosStatus();

  _statusTimer = Timer.periodic(
    const Duration(seconds: 5),
    (timer) {
      _loadSosStatus();
    },
  );
}

Future<void> _loadSosStatus() async {
  final data = await _getSosStatus();

  if (!mounted) return;

  setState(() {
    _sosStatus = data?['status']?.toString();
    _officerName = data?['officer_name']?.toString();
  });
}
@override
void dispose() {
  _statusTimer?.cancel();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F7),
      appBar: AppBar(
  backgroundColor: Colors.red,
  foregroundColor: Colors.white,
  title: const Text('Emergency SOS'),
  actions: [
    IconButton(
      tooltip: 'SOS History',
      icon: const Icon(Icons.history),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const SosHistoryScreen(),
          ),
        );
      },
    ),
  ],
),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sos, color: Colors.red, size: 110),
              const SizedBox(height: 24),
              const Text(
                'Need immediate help?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
  'Send an SOS only during an emergency. '
  'Your current location will be shared with the rescue team. '
  'Medical details will be shared only if medical sharing is enabled.',
  textAlign: TextAlign.center,
  style: TextStyle(
    fontSize: 16,
    color: Colors.black54,
  ),
),
              if (_sending) ...[
  const CircularProgressIndicator(
    color: Colors.red,
  ),
  const SizedBox(height: 16),
  Text(
    _status,
    textAlign: TextAlign.center,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Colors.red,
    ),
  ),
  const SizedBox(height: 20),
],
if (_sosStatus != null) ...[
  const SizedBox(height: 20),

  Card(
    color: _sosStatus == 'acknowledged'
        ? Colors.green.shade50
        : _sosStatus == 'resolved'
            ? Colors.blue.shade50
            : Colors.orange.shade50,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            _sosStatus == 'acknowledged'
                ? Icons.check_circle
                : _sosStatus == 'resolved'
                    ? Icons.verified
                    : Icons.pending,
            color: _sosStatus == 'acknowledged'
                ? Colors.green
                : _sosStatus == 'resolved'
                    ? Colors.blue
                    : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _sosStatus == 'acknowledged'
            ? 'Your emergency has been acknowledged.'
            : _sosStatus == 'resolved'
                ? 'Your emergency has been marked as resolved.'
                : 'Your SOS has been sent. Waiting for an officer.',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),

      if (_sosStatus == 'acknowledged' &&
          _officerName != null &&
          _officerName!.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(
          '👮 Acknowledged by: $_officerName',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ],
  ),
),
        ],
      ),
    ),
  ),
],
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _sending ? null : _sendSos,
                  icon: _sending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.warning_amber_rounded),
                  label: Text(_sending ? 'SENDING SOS…' : 'SEND SOS', style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
  onPressed: _sending
    ? null
    : () {
        setState(() {
          _sending = false;
          _status = '';
          _countdown = 0;
        });

        if (widget.onCancel != null) {
          widget.onCancel!();
        } else {
          Navigator.of(context).maybePop();
        }
      },
  child: const Text('Cancel'),
),
            ],
          ),
        ),
      ),
    );
  }
}
