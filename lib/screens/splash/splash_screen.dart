import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cctv/cctv_camera_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/login_screen.dart';
import '../citizen/bottom_navigation.dart';
import '../rescue/rescue_dashboard.dart';
import '../officer/officer_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../cctv/cctv_device_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _startApp();
  }

  Future<void> _startApp() async {
  await Future.delayed(
    const Duration(seconds: 2),
  );

  if (!mounted) return;

  final prefs =
      await SharedPreferences.getInstance();

  // First-time onboarding status
  final onboardingCompleted =
      prefs.getBool('onboarding_completed') ??
          false;

  // Current Firebase login session
  final User? currentUser =
      FirebaseAuth.instance.currentUser;

  // ============================================================
  // EXISTING LOGGED-IN USER
  // ============================================================

  if (currentUser != null) {
    await _openDashboard(currentUser.uid);
    return;
  }

  // ============================================================
  // USER NOT LOGGED IN
  // ============================================================

  if (!onboardingCompleted) {
    _openOnboarding();
  } else {
    _openLogin();
  }
}

  // ============================================================
  // OPEN ONBOARDING
  // ============================================================

  void _openOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
      ),
    );
  }

  // ============================================================
  // OPEN LOGIN
  // ============================================================

  void _openLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  // ============================================================
  // OPEN CORRECT DASHBOARD
  // ============================================================

  Future<void> _openDashboard(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!mounted) return;

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();

        _openLogin();
        return;
      }

      final data = userDoc.data();

      if (data == null) {
        await FirebaseAuth.instance.signOut();

        _openLogin();
        return;
      }

      final String role = data['role'] ?? '';

      // ============================================================
      // CITIZEN
      // ============================================================

      if (role == 'Citizen') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const BottomNavigation(),
          ),
        );
        return;
      }

      // ============================================================
      // RESCUE
      // ============================================================

      if (role == 'Rescue') {
        final String verificationStatus =
            data['verificationStatus'] ?? 'Pending';

        final bool isApproved =
            data['isApproved'] ?? false;

        // If rejected, sign out and send to login.
        if (verificationStatus == 'Rejected') {
          await FirebaseAuth.instance.signOut();

          _openLogin();
          return;
        }

        // Your existing project currently opens RescueDashboard
        // for both pending and approved rescue accounts.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RescueDashboard(),
          ),
        );
        return;
      }

      // ============================================================
      // OFFICER
      // ============================================================

      if (role == 'Officer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const OfficerDashboard(),
          ),
        );
        return;
      }
      // ============================================================
// CCTV
// ============================================================

if (role == 'CCTV') {
  final prefs =
      await SharedPreferences.getInstance();

  final deviceId =
      prefs.getString('cctv_device_id');

  final cameraName =
      prefs.getString('cctv_camera_name');

  if (deviceId != null &&
      deviceId.isNotEmpty &&
      cameraName != null &&
      cameraName.isNotEmpty) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CctvCameraScreen(
          deviceId: deviceId,
          cameraName: cameraName,
        ),
      ),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CctvDeviceSetupScreen(),
      ),
    );
  }

  return;
}

      // ============================================================
      // ADMIN
      // ============================================================

      if (role == 'Admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminDashboard(),
          ),
        );
        return;
      }

      // ============================================================
      // INVALID ROLE
      // ============================================================

      await FirebaseAuth.instance.signOut();

      _openLogin();
    } catch (e) {
      debugPrint('Splash dashboard error: $e');

      if (!mounted) return;

      await FirebaseAuth.instance.signOut();

      _openLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF031B49),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/aegis_logo.png',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 110,
                );
              },
            ),

            const SizedBox(height: 18),

            const Text(
              'AEGIS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 5,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'AI-POWERED DISASTER RESPONSE SYSTEM',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF4DA3FF),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 35),

            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF4DA3FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}