import 'rescue_profile_screen.dart';
import 'package:flutter/material.dart';
import 'assigned_cases_screen.dart';
import 'team_members_screen.dart';
import 'mission_history_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../common/notification_screen.dart';
import '../common/session_actions.dart';
import '../common/settings_screen.dart';
import 'ai_camera_screen.dart';

class RescueDashboard extends StatefulWidget {
  const RescueDashboard({super.key});

  @override
  State<RescueDashboard> createState() =>
      _RescueDashboardState();
}

class _RescueDashboardState extends State<RescueDashboard> {

  Timer? locationTimer;
  bool locationStarted = false;

  Future<void> openGoogleMaps(
    double latitude,
    double longitude,
  ) async {

    final Uri url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> updateLiveLocation() async {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  Position position =
      await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
    ),
  );

  // Update user profile location
  await FirebaseFirestore.instance
      .collection("users")
      .doc(userId)
      .set({
    "latitude": position.latitude,
    "longitude": position.longitude,
    "lastUpdated": Timestamp.now(),
    "locationAvailable": true,
  }, SetOptions(merge: true));

  // Update rescue team location used by AI assignment
  await FirebaseFirestore.instance
      .collection("rescueTeams")
      .doc(userId)
      .set({
    "latitude": position.latitude,
    "longitude": position.longitude,
    "lastUpdated": Timestamp.now(),
    "locationAvailable": true,
  }, SetOptions(merge: true));
}
  void startLocationTracking() {
  if (locationStarted) return;

  locationStarted = true;

  updateLiveLocation();

  locationTimer = Timer.periodic(
    const Duration(seconds: 10),
    (timer) {
      updateLiveLocation();
    },
  );
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
  backgroundColor: const Color(0xFF087F5B),
  foregroundColor: Colors.white,
  title: const Text("Rescue Team"),

  actions: [

    StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection("notifications")
      .where(
        "receiverId",
        isEqualTo:
            FirebaseAuth.instance.currentUser!.uid,
      )
      .where("isRead", isEqualTo: false)
      .snapshots(),
  builder: (context, snapshot) {

    int unread =
        snapshot.data?.docs.length ?? 0;

    return Stack(
      children: [

        IconButton(
          tooltip: "Notifications",
          icon: const Icon(Icons.notifications),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const NotificationScreen(),
              ),
            );
          },
        ),

        if (unread > 0)

          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding:
                  const EdgeInsets.all(4),
              decoration:
                  const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                unread.toString(),
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),

      ],
    );
  },
),

    IconButton(
      icon: const Icon(Icons.person),
      tooltip: "Profile",
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RescueProfileScreen(),
          ),
        );
      },
    ),

    IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: "Settings",
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen(role: "Rescue")),
      ),
    ),

    IconButton(
  icon: const Icon(Icons.logout),
  tooltip: "Logout",
  onPressed: () => SessionActions.confirmLogout(context),
),

  ],
),

      body: StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection("users")
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .snapshots(),

  builder: (context, snapshot) {

    if (snapshot.connectionState ==
        ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!snapshot.hasData ||
        !snapshot.data!.exists) {
      return const Center(
        child: Text(
          "Unable to load account information.",
        ),
      );
    }

    final userData =
        snapshot.data!.data()
            as Map<String, dynamic>;

    final bool isApproved =
        userData["isApproved"] ?? false;

    final String verificationStatus =
        userData["verificationStatus"] ??
            "Pending";

    // =========================
    // PENDING RESCUE
    // =========================

    if (verificationStatus == "Rejected") {
  return ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const SizedBox(height: 40),

      const Icon(
        Icons.cancel_outlined,
        size: 90,
        color: Colors.red,
      ),

      const SizedBox(height: 20),

      const Text(
        "Rescue Application Rejected",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),

      const SizedBox(height: 15),

      const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "Your Rescue Team application has been rejected "
            "by a Government Officer. You cannot access "
            "rescue operations.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ),

      const SizedBox(height: 20),

      _lockedAction(
        Icons.assignment_late_outlined,
        "Emergency Missions",
      ),

      _lockedAction(
        Icons.location_on_outlined,
        "Live Location",
      ),

      _lockedAction(
        Icons.report_outlined,
        "Assigned Cases",
      ),

      _lockedAction(
        Icons.groups_outlined,
        "Team Operations",
      ),
    ],
  );
}

if (!isApproved) {
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [

          const SizedBox(height: 20),

          const Icon(
            Icons.hourglass_top_rounded,
            size: 80,
            color: Colors.orange,
          ),

          const SizedBox(height: 20),

          const Text(
            "Rescue Team Dashboard",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  const Icon(
                    Icons.verified_user_outlined,
                    size: 45,
                    color: Colors.orange,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Verification Pending",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Your Rescue Team account is currently "
                    "waiting for approval from a Government Officer.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "Status: $verificationStatus",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            "Operational Access",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _lockedAction(
            Icons.assignment_late_outlined,
            "Emergency Missions",
          ),

          _lockedAction(
            Icons.location_on_outlined,
            "Live Location",
          ),

          _lockedAction(
            Icons.report_outlined,
            "Assigned Cases",
          ),

          _lockedAction(
            Icons.groups_outlined,
            "Team Operations",
          ),

          const SizedBox(height: 20),

          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [

                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      "Your operational features will "
                      "automatically become available after "
                      "Officer approval.",
                    ),
                  ),

                ],
              ),
            ),
          ),
        ],
      );
    }

    // =========================
    // APPROVED RESCUE
    // =========================

    startLocationTracking();
return _buildApprovedDashboard(context);
  },
),
      ),
    );
  }
  Widget _lockedAction(
  IconData icon,
  String title,
) {
  return Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor:
            Colors.grey.withOpacity(0.12),
        child: Icon(
          icon,
          color: Colors.grey,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
      trailing: const Icon(
        Icons.lock_outline,
        color: Colors.grey,
      ),
    ),
  );
}
Widget _buildApprovedDashboard(
  BuildContext context,
) {
  return ListView(
    padding: const EdgeInsets.all(18),
    children: [

      const Text(
        "Operations Dashboard",
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 5),

      const Text(
        "Manage assigned emergency cases.",
      ),

      const SizedBox(height: 20),

      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [

            Icon(
              Icons.verified,
              color: Colors.green,
            ),

            SizedBox(width: 10),

            Expanded(
              child: Text(
                "Verified Rescue Team — "
                "Operational access enabled.",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),

          ],
        ),
      ),
      Card(
  margin: const EdgeInsets.only(bottom: 12),
  child: ListTile(
    leading: const CircleAvatar(
      backgroundColor: Color(0xFFE8F5E9),
      child: Icon(
        Icons.camera_alt_rounded,
        color: Color(0xFF087F5B),
      ),
    ),
    title: const Text(
      "AI Rescue Camera",
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: const Text(
      "Live AI detection, thermal & radar simulation",
    ),
    trailing: const Icon(
      Icons.chevron_right,
    ),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AICameraScreen(),
        ),
      );
    },
  ),
),

const SizedBox(height: 12),

      const SizedBox(height: 20),

      StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection("reports")
      .where(
        "assignedTo",
        isEqualTo:
            FirebaseAuth.instance.currentUser!.uid,
      )
      .where(
        "status",
        whereIn: [
          "Assigned",
          "In Progress",
        ],
      )
      .snapshots(),
  builder: (context, snapshot) {
    final activeCount =
        snapshot.data?.docs.length ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AssignedCasesScreen(),
          ),
        );
      },
      child: _summaryCard(
        "Active Assignments",
        activeCount.toString(),
        Icons.assignment_late_outlined,
        Colors.red,
      ),
    );
  },
),

      const SizedBox(height: 12),

      StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection("teamMembers")
      .where(
        "teamId",
        isEqualTo:
            FirebaseAuth.instance.currentUser!.uid,
      )
      .where(
        "status",
        isEqualTo: "Available",
      )
      .snapshots(),
  builder: (context, snapshot) {

    final availableCount =
        snapshot.data?.docs.length ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const TeamMembersScreen(),
          ),
        );
      },
      child: _summaryCard(
        "Available Team Members",
        availableCount.toString(),
        Icons.groups_outlined,
        Colors.green,
      ),
    );
  },
),
      const SizedBox(height: 12),

GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const MissionHistoryScreen(),
      ),
    );
  },
  child: _summaryCard(
    "Mission History",
    "View",
    Icons.history,
    Colors.blue,
  ),
),

      const SizedBox(height: 25),

      const Text(
        "Assigned Cases",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 12),

      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("reports")
            .where(
              "assignedTo",
              isEqualTo:
                  FirebaseAuth.instance
                      .currentUser!
                      .uid,
            )
            .where(
  "status",
  whereIn: [
    "Assigned",
    "In Progress",
  ],
)
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Text(
              "No Assigned Cases",
            );
          }

          final reports =
              snapshot.data!.docs;

          return ListView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount: reports.length,

            itemBuilder: (context, index) {

              final report =
                  reports[index].data()
                      as Map<String, dynamic>;

              return _caseCard(
  context,
  report["title"] ?? report["disasterType"] ?? "",
  report["location"] ?? "",
  report["severity"] ?? "",
  report["status"] ?? "Assigned",
  report["imageUrl"] ?? "",
  report["description"] ?? "",
  report["peopleCount"] ?? 0,
  report["aiAnalyzed"] ?? false,
  reports[index].id,
  (report["latitude"] as num?)?.toDouble() ?? 0.0,
  (report["longitude"] as num?)?.toDouble() ?? 0.0,
);
            },
          );
        },
      ),
    ],
  );
}
 
  Widget _summaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(
            icon,
            color: Colors.red,
          ),
        ),
        title: Text(label),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

 Widget _caseCard(
  BuildContext context,
  String title,
  String location,
  String severity,
  String status,
  String imageUrl,
  String description,
  dynamic peopleCount,
  bool aiAnalyzed,
  String documentId,
  double latitude,
  double longitude,
) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Disaster title
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Status
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: status == "Assigned"
                  ? Colors.orange.shade100
                  : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: status == "Assigned"
                    ? Colors.orange.shade900
                    : Colors.blue.shade900,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Disaster image
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return Container(
                    height: 120,
                    alignment: Alignment.center,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 40,
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 12),

          // Description
          if (description.isNotEmpty) ...[
            const Text(
              "Description",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(description),
            const SizedBox(height: 12),
          ],

          // Severity
          Row(
            children: [
              const Icon(
                Icons.priority_high,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                "Severity: $severity",
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(location),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Coordinates
          Text(
            "Coordinates: "
            "${latitude.toStringAsFixed(6)}, "
            "${longitude.toStringAsFixed(6)}",
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 12),

          // AI Analysis card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: aiAnalyzed
                  ? Colors.purple.shade50
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: aiAnalyzed
                    ? Colors.purple.shade200
                    : Colors.grey.shade300,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      color: aiAnalyzed
                          ? Colors.purple
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      aiAnalyzed
                          ? "AI Analysis Completed"
                          : "AI Analysis Not Available",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(Icons.people_outline),
                    const SizedBox(width: 8),
                    Text(
                      "People Detected: $peopleCount",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // Google Maps button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: latitude != 0.0 && longitude != 0.0
                  ? () => openGoogleMaps(
                        latitude,
                        longitude,
                      )
                  : null,
              icon: const Icon(Icons.map_outlined),
              label: const Text(
                "Open Incident Location",
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Mission button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {

                if (status == "Assigned") {

                  await FirebaseFirestore.instance
                      .collection("reports")
                      .doc(documentId)
                      .update({
                    "status": "In Progress",
                    "acceptedAt": Timestamp.now(),
                  });

                  // Get report information
                  final reportDoc =
                      await FirebaseFirestore.instance
                          .collection("reports")
                          .doc(documentId)
                          .get();

                  final reportData =
                      reportDoc.data() as Map<String, dynamic>;

                  final officerId =
                      reportData["officerId"];

                  if (officerId != null &&
                      officerId.toString().isNotEmpty) {

                    await FirebaseFirestore.instance
                        .collection("notifications")
                        .add({
                      "receiverId": officerId,
                      "title": "🚑 Mission Accepted",
                      "body":
                          "${reportData["assignedName"] ?? "Rescue Team"} "
                          "has accepted "
                          "'${reportData["title"] ?? "mission"}'.",
                      "type": "mission_accepted",
                      "reportId": documentId,
                      "isRead": false,
                      "timestamp": Timestamp.now(),
                    });
                  }

                  if (context.mounted) {
                    _message(
                      context,
                      "Mission Accepted",
                    );
                  }

                } else if (status == "In Progress") {

                  final userId =
                      FirebaseAuth.instance.currentUser!.uid;

                  final batch =
                      FirebaseFirestore.instance.batch();

                  // Complete report
                  batch.update(
                    FirebaseFirestore.instance
                        .collection("reports")
                        .doc(documentId),
                    {
                      "status": "Completed",
                      "completedAt": Timestamp.now(),
                    },
                  );

                  // Make rescue team available again
                  batch.update(
                    FirebaseFirestore.instance
                        .collection("rescueTeams")
                        .doc(userId),
                    {
                      "status": "Available",
                      "currentReportId": null,
                    },
                  );

                  await batch.commit();

                  // Get report information
                  final reportDoc =
                      await FirebaseFirestore.instance
                          .collection("reports")
                          .doc(documentId)
                          .get();

                  final reportData =
                      reportDoc.data()
                          as Map<String, dynamic>;

                  final officerId =
                      reportData["officerId"];

                  if (officerId != null &&
                      officerId.toString().isNotEmpty) {

                    await FirebaseFirestore.instance
                        .collection("notifications")
                        .add({
                      "receiverId": officerId,
                      "title": "✅ Mission Completed",
                      "body":
                          "${reportData["assignedName"] ?? "Rescue Team"} "
                          "has completed "
                          "'${reportData["title"] ?? "mission"}'. "
                          "Officer verification is required.",
                      "type": "mission_completed",
                      "reportId": documentId,
                      "isRead": false,
                      "timestamp": Timestamp.now(),
                    });
                  }

                  if (context.mounted) {
                    _message(
                      context,
                      "Mission Completed",
                    );
                  }
                }
              },
              icon: Icon(
                status == "Assigned"
                    ? Icons.play_arrow
                    : Icons.check_circle,
              ),
              label: Text(
                status == "Assigned"
                    ? "Accept Mission"
                    : "Complete Mission",
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  void _message(
    BuildContext context,
    String value,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
      ),
    );
  }
  @override
void dispose() {
  locationTimer?.cancel();
  super.dispose();
}
}
