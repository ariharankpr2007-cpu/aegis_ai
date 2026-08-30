import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OfficerRegistrationScreen extends StatefulWidget {
  const OfficerRegistrationScreen({super.key});

  @override
  State<OfficerRegistrationScreen> createState() =>
      _OfficerRegistrationScreenState();
}

class _OfficerRegistrationScreenState
    extends State<OfficerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController officerIdController =
    TextEditingController();

final TextEditingController passwordController =
    TextEditingController();

final TextEditingController confirmPasswordController =
    TextEditingController();

bool verifying = false;
bool creatingAccount = false;

Map<String, dynamic>? verifiedOfficer;
String? verifiedOfficerId;

  @override
void dispose() {
  officerIdController.dispose();
  passwordController.dispose();
  confirmPasswordController.dispose();
  super.dispose();
}

  Future<void> verifyOfficer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      verifying = true;
    });

    try {
      final officerId =
          officerIdController.text.trim().toUpperCase();

      final doc = await FirebaseFirestore.instance
          .collection("officerRegistry")
          .doc(officerId)
          .get();

      if (!doc.exists) {
        throw Exception(
          "Officer ID could not be verified.",
        );
      }

      final data =
          doc.data() as Map<String, dynamic>;

      if (data["active"] != true) {
        throw Exception(
          "This Officer ID is inactive.",
        );
      }
      if (!mounted) return;

      setState(() {
  verifiedOfficer = data;
  verifiedOfficerId = officerId;
});
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
  Future<void> createOfficerAccount() async {
  if (verifiedOfficer == null ||
      verifiedOfficerId == null) {
    return;
  }

  final password = passwordController.text.trim();
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
      verifiedOfficer!["email"]?.toString().trim();

  if (email == null || email.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "No registered email found for this Officer ID.",
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
      "name": verifiedOfficer!["name"],
      "email": email,
      "role": "Officer",
      "officerId": verifiedOfficerId,
      "department": verifiedOfficer!["department"],
      "state": verifiedOfficer!["state"],
      "district": verifiedOfficer!["district"],
      "status": "Active",
      "isApproved": true,
      "verificationStatus": "Approved",
      "createdAt": Timestamp.now(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Officer account activated successfully.",
        ),
      ),
    );

    Navigator.pop(context);
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.message ?? "Failed to create officer account.",
        ),
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
        title: const Text("Officer Registration"),
        backgroundColor: const Color(0xFF0B3D91),
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
                "Officer Registration",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Register using your official Officer ID.",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 25),

              TextFormField(
                controller: officerIdController,
                textCapitalization:
                    TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: "Official Officer ID",
                  hintText: "Example: TN-CHN-001",
                  prefixIcon:
                      Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return "Enter your Officer ID";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

if (verifiedOfficer != null)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(12),
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
              "Officer Verified",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Text(
          "Name: ${verifiedOfficer!["name"]}",
        ),

        Text(
          "Officer ID: $verifiedOfficerId",
        ),

        Text(
          "Department: ${verifiedOfficer!["department"]}",
        ),

        Text(
          "District: ${verifiedOfficer!["district"]}",
        ),

        Text(
          "State: ${verifiedOfficer!["state"]}",
        ),

        Text(
          "Registered Email: ${verifiedOfficer!["email"]}",
        ),
      ],
    ),
  ),

if (verifiedOfficer != null)
  const SizedBox(height: 20),

if (verifiedOfficer != null)
  TextFormField(
    controller: passwordController,
    obscureText: true,
    decoration: const InputDecoration(
      labelText: "Create Password",
      prefixIcon: Icon(Icons.lock_outline),
      border: OutlineInputBorder(),
    ),
  ),

if (verifiedOfficer != null)
  const SizedBox(height: 15),

if (verifiedOfficer != null)
  TextFormField(
    controller: confirmPasswordController,
    obscureText: true,
    decoration: const InputDecoration(
      labelText: "Confirm Password",
      prefixIcon: Icon(Icons.lock_outline),
      border: OutlineInputBorder(),
    ),
  ),

if (verifiedOfficer != null)
  const SizedBox(height: 20),

if (verifiedOfficer != null)
  SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton.icon(
      onPressed:
          creatingAccount
              ? null
              : createOfficerAccount,
      icon: creatingAccount
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.person_add),
      label: Text(
        creatingAccount
            ? "Creating Account..."
            : "Activate Officer Account",
      ),
    ),
  ),

if (verifiedOfficer == null)
  SizedBox(
    width: double.infinity,
    height: 52,
                child: ElevatedButton.icon(
                  onPressed:
                      verifying ? null : verifyOfficer,
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
                        : "Verify Officer ID",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}