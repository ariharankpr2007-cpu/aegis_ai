import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../rescue/rescue_registration_screen.dart';
import '../citizen/bottom_navigation.dart';
import '../rescue/rescue_dashboard.dart';
import '../officer/officer_dashboard.dart';
import '../officer/officer_registration_screen.dart';
import 'register_screen.dart';
import '../admin/admin_dashboard.dart';
import '../onboarding/onboarding_screen.dart';
import '../../services/notification_service.dart';
import '../cctv/cctv_device_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  String _selectedRole = "Citizen";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String> _resolveLoginEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      throw Exception('Enter your email address.');
    }

    return email;
  }

  Future<void> _login() async {

  try {

    final email = await _resolveLoginEmail();
    UserCredential userCredential =
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(

      email: email,
      password: _passwordController.text.trim(),

    );

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance
            .collection("users")
            .doc(userCredential.user!.uid)
            .get();

    if (!userDoc.exists) {
      await auth.signOut();
      throw Exception('Your account profile could not be found.');
    }

    String role = userDoc["role"];

    if (role != _selectedRole) {
      await auth.signOut();
      throw Exception('This account is registered as $role, not $_selectedRole.');
    }

    if (!mounted) return;

    if (role == "Citizen") {

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const BottomNavigation(),
    ),
  );

} else if (role == "Rescue") {

  String verificationStatus =
      userDoc["verificationStatus"] ?? "Pending";

  bool isApproved =
      userDoc["isApproved"] ?? false;

  if (verificationStatus == "Rejected") {

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Your Rescue Team application was rejected by the officer.",
        ),
      ),
    );

    return;
  }

  if (!isApproved ||
      verificationStatus != "Approved") {

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const RescueDashboard(),
      ),
    );

    return;
  }

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const RescueDashboard(),
    ),
  );

} else if (role == "Officer") {
  await NotificationService().initialize();
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const OfficerDashboard(),
    ),
  );
  } else if (role == "CCTV") {

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const CctvDeviceSetupScreen(),
    ),
  );

} else if (role == "Admin") {

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const AdminDashboard(),
    ),
  );

} else {

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Invalid user role."),
    ),
  );

}

  }  on FirebaseAuthException catch (e) {

  print("LOGIN ERROR CODE: ${e.code}");
  print("LOGIN ERROR MESSAGE: ${e.message}");

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        "${e.code}: ${e.message ?? "Login Failed"}",
      ),
    ),
  );

} on Exception catch (e) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
  );

}

}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: const Color(0xFF0B3D91),

  appBar: AppBar(
    backgroundColor: const Color(0xFF0B3D91),
    foregroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) => const OnboardingScreen(),
    ),
    (route) => false,
  );
},
    ),
    title: const Text(
      'Sign In',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 28),
              const CircleAvatar(
                radius: 54,
                backgroundColor: Colors.white,
                child: Icon(Icons.shield_outlined, color: Color(0xFF0B3D91), size: 64),
              ),
              const SizedBox(height: 18),
              const Text('AEGIS AI', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 7),
              const Text('AI Powered Disaster Management', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  children: [
                    const SizedBox(height: 18),

DropdownButtonFormField<String>(
  value: _selectedRole,
  decoration: const InputDecoration(
    labelText: "Login as",
    prefixIcon: Icon(Icons.person_outline),
    border: OutlineInputBorder(),
  ),
  items: const [
    DropdownMenuItem(
      value: "Citizen",
      child: Text("Citizen"),
    ),
    DropdownMenuItem(
      value: "Officer",
      child: Text("Officer"),
    ),
    DropdownMenuItem(
      value: "Rescue",
      child: Text("Rescue Team"),
    ),
    DropdownMenuItem(
  value: "CCTV",
  child: Text("CCTV Camera"),
),
    DropdownMenuItem(
      value: "Admin",
      child: Text("Admin"),
    ),
  ],
  onChanged: (value) {
    if (value == null) return;

    setState(() {
      _selectedRole = value;
      _emailController.clear();
      _passwordController.clear();
    });
  },
),

const SizedBox(height: 18),

TextField(
  controller: _emailController,
  keyboardType: TextInputType.emailAddress,
  decoration: InputDecoration(
    labelText: "Email",
    prefixIcon: const Icon(Icons.email_outlined),
    border: const OutlineInputBorder(),
  ),
),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
  onPressed: () async {

    try {

      final email = await _resolveLoginEmail();

      await FirebaseAuth.instance
          .sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Password reset email sent. Check your inbox.",
          ),
        ),
      );

    } on FirebaseAuthException catch (e) {

      String message = e.message ??
          "Failed to send password reset email.";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

    } on Exception catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst("Exception: ", ""),
          ),
        ),
      );

    }

  },
  child: const Text('Forgot password?'),
),
),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B3D91)),
                        onPressed: _login,
                        child: const Text('LOGIN', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_selectedRole != "Admin") TextButton(
  onPressed: () {
    if (_selectedRole == "Officer") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const OfficerRegistrationScreen(),
        ),
      );
    } else if (_selectedRole == "Rescue") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const RescueRegistrationScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const RegisterScreen(),
        ),
      );
    }
  },
  child: Text(
    _selectedRole == "Officer"
        ? "New Officer? Register"
        : _selectedRole == "Rescue"
            ? "New Rescue Team? Register"
            : "Create New Account",
  ),
),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
