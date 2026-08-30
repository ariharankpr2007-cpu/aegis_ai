import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RescueRegistrationScreen extends StatefulWidget {
  const RescueRegistrationScreen({super.key});

  @override
  State<RescueRegistrationScreen> createState() =>
      _RescueRegistrationScreenState();
}

class _RescueRegistrationScreenState
    extends State<RescueRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController teamIdController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool verifying = false;
  bool creatingAccount = false;

  Map<String, dynamic>? verifiedTeam;
  String? verifiedTeamId;

  @override
  void dispose() {
    teamIdController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> verifyRescueTeam() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      verifying = true;
    });

    try {
      final teamId =
          teamIdController.text.trim().toUpperCase();

      final doc = await FirebaseFirestore.instance
          .collection("rescueTeamRegistry")
          .doc(teamId)
          .get();

      if (!doc.exists) {
        throw Exception(
          "Rescue Team ID could not be verified.",
        );
      }

      final data =
          doc.data() as Map<String, dynamic>;

      if (data["active"] != true) {
        throw Exception(
          "This Rescue Team ID is inactive.",
        );
      }

      final email =
          data["email"]?.toString().trim();

      if (email == null || email.isEmpty) {
        throw Exception(
          "No registered email found for this Rescue Team ID.",
        );
      }

      if (!mounted) return;

      setState(() {
        verifiedTeam = data;
        verifiedTeamId = teamId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Rescue Team verified: "
            "${data["teamName"] ?? teamId}",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          verifying = false;
        });
      }
    }
  }

  Future<void> createRescueAccount() async {
    if (verifiedTeam == null ||
        verifiedTeamId == null) {
      return;
    }

    final password =
        passwordController.text.trim();

    final confirmPassword =
        confirmPasswordController.text.trim();

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Password must be at least 6 characters.",
          ),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Passwords do not match.",
          ),
        ),
      );
      return;
    }

    final email =
        verifiedTeam!["email"]?.toString().trim();

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "No registered email found.",
          ),
        ),
      );
      return;
    }

    setState(() {
      creatingAccount = true;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set({
        "uid": uid,
        "name": verifiedTeam!["teamName"],
        "teamName": verifiedTeam!["teamName"],
        "email": email,
        "role": "Rescue",
        "teamId": verifiedTeamId,
        "department": verifiedTeam!["department"],
        "state": verifiedTeam!["state"],
        "district": verifiedTeam!["district"],
        "specialization":
            verifiedTeam!["specialization"],
        "status": "Active",
        "isApproved": true,
        "verificationStatus": "Approved",
        "createdAt": Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Rescue Team account activated successfully.",
          ),
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      if (e.code == "email-already-in-use") {
        message =
            "This Rescue Team email already has an account.";
      } else if (e.code == "weak-password") {
        message =
            "The password is too weak.";
      } else if (e.code == "invalid-email") {
        message =
            "The registered email address is invalid.";
      } else {
        message =
            e.message ??
                "Failed to create Rescue Team account.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Account creation failed: $e",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          creatingAccount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Rescue Team Registration",
        ),
        backgroundColor:
            const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                "Rescue Team Registration",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Register using your official "
                "Rescue Team ID.",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 30),

              TextFormField(
                controller: teamIdController,
                enabled: verifiedTeam == null,
                textCapitalization:
                    TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: "Official Team ID",
                  hintText: "Example: TN-RES-001",
                  prefixIcon:
                      Icon(Icons.groups_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return "Enter your Team ID";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 25),

              if (verifiedTeam == null)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: verifying
                        ? null
                        : verifyRescueTeam,
                    icon: verifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.verified_outlined,
                          ),
                    label: Text(
                      verifying
                          ? "Verifying..."
                          : "Verify Team ID",
                    ),
                  ),
                ),

              if (verifiedTeam != null) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Rescue Team Verified",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "Team Name: "
                        "${verifiedTeam!["teamName"]}",
                      ),

                      Text(
                        "Team ID: $verifiedTeamId",
                      ),

                      Text(
                        "Department: "
                        "${verifiedTeam!["department"]}",
                      ),

                      Text(
                        "District: "
                        "${verifiedTeam!["district"]}",
                      ),

                      Text(
                        "State: "
                        "${verifiedTeam!["state"]}",
                      ),

                      Text(
                        "Specialization: "
                        "${verifiedTeam!["specialization"]}",
                      ),

                      Text(
                        "Registered Email: "
                        "${verifiedTeam!["email"]}",
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Your jurisdiction has been "
                        "automatically assigned.",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(
                    labelText: "Create Password",
                    prefixIcon:
                        Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller:
                      confirmPasswordController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon:
                        Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: creatingAccount
                        ? null
                        : createRescueAccount,
                    icon: creatingAccount
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.person_add,
                          ),
                    label: Text(
                      creatingAccount
                          ? "Creating Account..."
                          : "Activate Rescue Account",
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}