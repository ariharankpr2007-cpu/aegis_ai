import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RescuePendingScreen extends StatelessWidget {
  const RescuePendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF087F5B),
        foregroundColor: Colors.white,
        title: const Text("Rescue Application"),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const Icon(
                    Icons.hourglass_top_rounded,
                    size: 70,
                    color: Colors.orange,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Application Submitted",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Your Rescue Team application is currently "
                    "pending verification by a Government Officer.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "You will be able to access the Rescue Dashboard "
                    "after your application has been approved.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();

                        if (!context.mounted) return;

                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          "/login",
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text("Back to Login"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}