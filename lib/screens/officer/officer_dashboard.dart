import 'package:flutter/material.dart';
import '../common/notification_screen.dart';
import 'live_disaster_map_screen.dart';
import 'broadcast_alert_screen.dart';
import 'ai_priority_reports_screen.dart';
import 'evidence_repository_screen.dart';
import 'disaster_reports_screen.dart';
import '../maps/live_map_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'analytics_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'rescue_applications_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../common/session_actions.dart';
import '../common/settings_screen.dart';
import 'officer_emergency_alerts_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mission_verification_screen.dart';
import 'mission_history_screen.dart';
import 'live_cctv_devices_screen.dart';

class OfficerDashboard extends StatefulWidget {
  const OfficerDashboard({super.key});

  @override
  State<OfficerDashboard> createState() =>
      _OfficerDashboardState();
}
class _OfficerDashboardState extends State<OfficerDashboard> {

  @override
  void initState() {
    super.initState();
    _updateOfficerLocation();
  }

  Future<void> _updateOfficerLocation() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) return;

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) return;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({
        "latitude": position.latitude,
        "longitude": position.longitude,
        "locationUpdatedAt": Timestamp.now(),
        "locationAvailable": true,
      });

      debugPrint(
        "Officer location updated: "
        "${position.latitude}, ${position.longitude}",
      );
    } catch (e) {
      debugPrint(
        "Officer location update failed: $e",
      );
    }
  }
  Future<int> _getActiveSosCount() async {
  try {
    final data = await Supabase.instance.client
        .from('emergency_alerts')
        .select('id')
        .eq('status', 'pending');

    return data.length;
  } catch (e) {
    debugPrint('Failed to load SOS count: $e');
    return 0;
  }
}

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
  backgroundColor: const Color(0xFF0B3D91),
  foregroundColor: Colors.white,
  title: const Text("Command Center"),

  actions: [

    StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("notifications")
          .where(
            "receiverId",
            isEqualTo: FirebaseAuth.instance.currentUser!.uid,
          )
          .where("isRead", isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {

        int unread = snapshot.data?.docs.length ?? 0;

        return Stack(
          children: [

            IconButton(
              icon: const Icon(Icons.notifications),
              tooltip: "Notifications",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationScreen(),
                  ),
                );
              },
            ),

            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unread.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

          ],
        );
      },
    ),

    IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: "Settings",
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen(role: "Officer")),
      ),
    ),

    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () => SessionActions.confirmLogout(context),
    ),

  ],
),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            "Government Officer Dashboard",
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Monitor reports and coordinate emergency response.",
          ),

          const SizedBox(height: 20),

         StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection("reports")
      .snapshots(),
  builder: (context, reportSnapshot) {

    if (!reportSnapshot.hasData) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final reports = reportSnapshot.data!.docs;

    int pending = reports.where((doc) {
      return doc["status"] == "Pending";
    }).length;

    int resolved = reports.where((doc) {
      return doc["status"] == "Resolved";
    }).length;
    int completed = reports.where((doc) {
  return doc["status"] == "Completed";
}).length;

    int totalReports = reports.length;

    int satelliteAnalyzed = 0;
int needsReview = 0;

for (final doc in reports) {
  final data =
      doc.data() as Map<String, dynamic>;

  final satellite =
      data["satelliteVerification"];

  if (satellite != null) {
    satelliteAnalyzed++;
  }

  if (satellite is Map) {
    final finalAnalysis =
        satellite["finalAegisAnalysis"];

    if (finalAnalysis is Map &&
        finalAnalysis["overallAssessment"]
                ?.toString() ==
            "NEEDS_REVIEW") {
      needsReview++;
    }
  }
}

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("rescueTeams")
          .snapshots(),
      builder: (context, rescueSnapshot) {

        if (!rescueSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        int rescueCount =
            rescueSnapshot.data!.docs.length;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [

            FutureBuilder<int>(
  future: _getActiveSosCount(),
  builder: (context, snapshot) {
    final activeSos = snapshot.data ?? 0;

    return _MetricCard(
      "Active SOS",
      activeSos.toString(),
      Icons.sos_outlined,
      Colors.red,
    );
  },
),

            _MetricCard(
              "Reports",
              totalReports.toString(),
              Icons.report_outlined,
              Colors.orange,
            ),

            _MetricCard(
              "Rescue Teams",
              rescueCount.toString(),
              Icons.groups_outlined,
              Colors.green,
            ),

            _MetricCard(
              "Resolved",
              resolved.toString(),
              Icons.check_circle_outline,
              Colors.indigo,
            ),
            _MetricCard(
  "Awaiting Verification",
  completed.toString(),
  Icons.verified_outlined,
  Colors.blue,
),
_MetricCard(
  "Satellite Analyzed",
  satelliteAnalyzed.toString(),
  Icons.satellite_alt,
  Colors.blue,
),

_MetricCard(
  "Needs Review",
  needsReview.toString(),
  Icons.rate_review_outlined,
  Colors.orange,
),

                   ],
        );
      },
    );
  },
),

          const SizedBox(height: 25),

          const Text(
            "Command Actions",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _action(
  context,
  Icons.sos,
  "Emergency SOS Alerts",
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const OfficerEmergencyAlertsScreen(),
      ),
    );
  },
),
_action(
  context,
  Icons.videocam,
  "Live CCTV",
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LiveCctvDevicesScreen(),
      ),
    );
  },
),
_action(
  context,
  Icons.satellite_alt,
  "Satellite Verification",
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DisasterReportsScreen(
          initialStatus: "Needs Satellite",
        ),
      ),
    );
  },
),
_action(
  context,
  Icons.history,
  "Mission History",
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const MissionHistoryScreen(),
      ),
    );
  },
),
          
          _action(
  context,
  Icons.verified_user_outlined,
  "Rescue Applications",
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const RescueApplicationsScreen(),
      ),
    );
  },
),
          _action(
            context,
            Icons.map,
            "Live Disaster Map",
            () {
              Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const LiveMapScreen(),
  ),
);
            },
          ),

          _action(
            context,
            Icons.campaign,
            "Broadcast Emergency Alert",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BroadcastAlertScreen(),
                ),
              );
            },
          ),

          _action(
            context,
            Icons.psychology,
            "AI Priority Reports",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AIPriorityReportsScreen(),
                ),
              );
            },
          ),

          _action(
            context,
            Icons.folder,
            "Evidence Repository",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EvidenceRepositoryScreen(),
                ),
              );
            },
          ),

          _action(
            context,
            Icons.assignment,
            "Disaster Reports",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DisasterReportsScreen(),
                ),
              );
            },
          ),
          _action(
  context,
  Icons.bar_chart,
  "Analytics",
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AnalyticsScreen(),
      ),
    );
  },
),
                ],
      ),
    ),
  );
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard(
    this.title,
    this.value,
    this.icon,
    this.color,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              color: color,
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
