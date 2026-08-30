import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RescueApplicationsScreen extends StatelessWidget {
  const RescueApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
        title: const Text("Rescue Applications"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .where("role", isEqualTo: "Rescue")
            .where("verificationStatus", isEqualTo: "Pending")
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Unable to load applications.\n${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          final applications =
              snapshot.data?.docs ?? [];

          if (applications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 15),
                  Text(
                    "No pending rescue applications",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: applications.length,
            itemBuilder: (context, index) {

              final doc = applications[index];

              final data =
                  doc.data() as Map<String, dynamic>;

              return Card(
                margin:
                    const EdgeInsets.only(bottom: 12),

                child: ListTile(
                  contentPadding:
                      const EdgeInsets.all(16),

                  leading: const CircleAvatar(
                    backgroundColor:
                        Color(0xFFE3F2FD),
                    child: Icon(
                      Icons.groups_outlined,
                      color: Color(0xFF0B3D91),
                    ),
                  ),

                  title: Text(
                    data["name"] ?? "Unknown",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),

                      Text(
                        data["email"] ?? "",
                      ),

                      Text(
                        data["phone"] ?? "",
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        "Status: Pending Verification",
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  trailing: const Icon(
                    Icons.chevron_right,
                  ),

                  onTap: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RescueApplicationDetailsScreen(
                          userId: doc.id,
                          data: data,
                        ),
                      ),
                    );

                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class RescueApplicationDetailsScreen
    extends StatelessWidget {

  final String userId;
  final Map<String, dynamic> data;

  const RescueApplicationDetailsScreen({
    super.key,
    required this.userId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
        title: const Text(
          "Rescue Application",
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          const Icon(
            Icons.verified_user_outlined,
            size: 80,
            color: Color(0xFF0B3D91),
          ),

          const SizedBox(height: 20),

          Text(
            data["name"] ?? "Unknown",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 25),

          _info(
            "Email",
            data["email"] ?? "",
          ),

          _info(
            "Phone",
            data["phone"] ?? "",
          ),

          _info(
            "Role",
            data["role"] ?? "",
          ),

          _info(
            "Verification",
            data["verificationStatus"] ?? "",
          ),

          const SizedBox(height: 30),

          const Text(
            "Proof Verification",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          if (data["aadharUrl"] != null &&
    data["aadharUrl"].toString().isNotEmpty)
  Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Submitted Proof",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Image.network(
          data["aadharUrl"],
          width: double.infinity,
          height: 300,
          fit: BoxFit.contain,

          loadingBuilder:
              (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return const SizedBox(
              height: 300,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          },

          errorBuilder:
              (context, error, stackTrace) {
            return const SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  "Unable to load submitted proof.",
                ),
              ),
            );
          },
        ),
      ],
    ),
  )
else
  const Card(
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Text(
        "No proof document was submitted.",
      ),
    ),
  ),

          const SizedBox(height: 30),

          Row(
            children: [

              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _reject(context);
                  },
                  child: const Text(
                    "REJECT",
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: FilledButton(
                  onPressed: () {
  _showAssignAreaDialog(context);
},
                  child: const Text(
                    "APPROVE",
                  ),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _info(
    String title,
    String value,
  ) {
    return Card(
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(value),
      ),
    );
  }
  Future<void> _showAssignAreaDialog(
  BuildContext context,
) async {
  final stateController =
      TextEditingController(text: "Tamil Nadu");

  final districtController =
      TextEditingController();

  final areaController =
      TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text("Assign Rescue Area"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextField(
                controller: stateController,
                decoration: const InputDecoration(
                  labelText: "State",
                  prefixIcon: Icon(Icons.map),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: districtController,
                decoration: const InputDecoration(
                  labelText: "District",
                  hintText: "Example: Chennai",
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: areaController,
                decoration: const InputDecoration(
                  labelText: "Local Area / Village / Town",
                  hintText: "Example: Karapakkam",
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
            ],
          ),
        ),

        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text("Cancel"),
          ),

          FilledButton(
            onPressed: () async {

              final state =
                  stateController.text.trim();

              final district =
                  districtController.text.trim();

              final area =
                  areaController.text.trim();

              if (state.isEmpty ||
                  district.isEmpty ||
                  area.isEmpty) {

                ScaffoldMessenger.of(dialogContext)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Please fill all location details",
                    ),
                  ),
                );

                return;
              }

              Navigator.pop(dialogContext);

              await _approve(
                context,
                state: state,
                district: district,
                area: area,
              );
            },
            child: const Text("Approve & Assign"),
          ),
        ],
      );
    },
  );

  stateController.dispose();
  districtController.dispose();
  areaController.dispose();
}

  Future<void> _approve(
  BuildContext context, {
  required String state,
  required String district,
  required String area,
}) async {

  try {

    final officerId =
        FirebaseAuth.instance.currentUser!.uid;

    // Update rescue user's approval
    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .update({
      "isApproved": true,
      "verificationStatus": "Approved",
      "state": state,
      "district": district,
      "area": area,
      "approvedAt": Timestamp.now(),
    });

    // Update rescue team details
    await FirebaseFirestore.instance
        .collection("rescueTeams")
        .doc(userId)
        .update({

      "isApproved": true,
      "verificationStatus": "Approved",

      // Geographic hierarchy
      "state": state,
      "district": district,
      "area": area,

      // District officer responsible
      "officerId": officerId,

      // Team availability
      "status": "Available",
      "isActive": true,

      "approvedAt": Timestamp.now(),
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          "Rescue team approved for $area.",
        ),
      ),
    );

    Navigator.pop(context);

  } catch (e) {

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          "Approval failed: $e",
        ),
      ),
    );
  }
}

  Future<void> _reject(
    BuildContext context,
  ) async {

    try {

      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .update({
        "isApproved": false,
        "verificationStatus": "Rejected",
        "rejectedAt": Timestamp.now(),
      });

      await FirebaseFirestore.instance
          .collection("rescueTeams")
          .doc(userId)
          .update({
        "isApproved": false,
        "verificationStatus": "Rejected",
        "status": "Rejected",
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Rescue application rejected.",
          ),
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Rejection failed: $e",
          ),
        ),
      );
    }
  }
}