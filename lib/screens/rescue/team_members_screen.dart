import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeamMembersScreen extends StatelessWidget {
  const TeamMembersScreen({super.key});

  Future<void> _showAddMemberDialog(
    BuildContext context,
  ) async {
    final nameController = TextEditingController();
    final roleController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Add Team Member"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Member Name",
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(
                  labelText: "Role",
                  hintText: "Example: Rescuer / Driver / Medic",
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
            ],
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
                final name = nameController.text.trim();
                final role = roleController.text.trim();

                if (name.isEmpty || role.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please enter member name and role",
                      ),
                    ),
                  );
                  return;
                }

                final teamId =
                    FirebaseAuth.instance.currentUser!.uid;

                await FirebaseFirestore.instance
                    .collection("teamMembers")
                    .add({
                  "name": name,
                  "role": role,
                  "teamId": teamId,
                  "status": "Available",
                  "createdAt": Timestamp.now(),
                });
                final availableMembers = await FirebaseFirestore.instance
    .collection("teamMembers")
    .where("teamId", isEqualTo: teamId)
    .where("status", isEqualTo: "Available")
    .limit(1)
    .get();

await FirebaseFirestore.instance
    .collection("rescueTeams")
    .doc(teamId)
    .update({
  "status": availableMembers.docs.isNotEmpty
      ? "Available"
      : "Unavailable",
});

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    roleController.dispose();
  }

  Future<void> _deleteMember(
    String memberId,
  ) async {
    await FirebaseFirestore.instance
        .collection("teamMembers")
        .doc(memberId)
        .delete();
  }
  Future<void> _updateTeamAvailability(
  String teamId,
) async {
  final snapshot = await FirebaseFirestore.instance
      .collection("teamMembers")
      .where("teamId", isEqualTo: teamId)
      .where("status", isEqualTo: "Available")
      .limit(1)
      .get();

  final hasAvailableMember =
      snapshot.docs.isNotEmpty;

  await FirebaseFirestore.instance
      .collection("rescueTeams")
      .doc(teamId)
      .update({
    "status": hasAvailableMember
        ? "Available"
        : "Unavailable",
  });
}

  @override
  Widget build(BuildContext context) {
    final teamId =
        FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Team Members"),
        backgroundColor: const Color(0xFF087F5B),
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF087F5B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text("Add Member"),
        onPressed: () => _showAddMemberDialog(context),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("teamMembers")
            .where(
              "teamId",
              isEqualTo: teamId,
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
            return const Center(
              child: Text(
                "No team members added yet.\nTap Add Member to create your rescue team.",
                textAlign: TextAlign.center,
              ),
            );
          }

          final members = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member =
                  members[index].data()
                      as Map<String, dynamic>;

              final memberId =
                  members[index].id;

              final name =
                  member["name"] ?? "Unknown";

              final role =
                  member["role"] ?? "Rescuer";

              final status =
                  member["status"] ?? "Available";

              final isAvailable =
                  status == "Available";

              return Card(
                margin:
                    const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAvailable
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    child: Icon(
                      Icons.person,
                      color: isAvailable
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),

                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(role),
                      const SizedBox(height: 3),
                      Text(
                        status,
                        style: TextStyle(
                          color: isAvailable
                              ? Colors.green
                              : Colors.orange,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  isThreeLine: true,

                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == "Available") {
  await FirebaseFirestore.instance
      .collection("teamMembers")
      .doc(memberId)
      .update({
    "status": "Available",
  });

  await _updateTeamAvailability(teamId);
}

                      if (value == "On Mission") {
  await FirebaseFirestore.instance
      .collection("teamMembers")
      .doc(memberId)
      .update({
    "status": "On Mission",
  });

  await _updateTeamAvailability(teamId);
}

                      if (value == "Remove") {
  await _deleteMember(memberId);

  await _updateTeamAvailability(teamId);
}
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "Available",
                        child: Text(
                          "Mark Available",
                        ),
                      ),
                      const PopupMenuItem(
                        value: "On Mission",
                        child: Text(
                          "Mark On Mission",
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: "Remove",
                        child: Text(
                          "Remove Member",
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}