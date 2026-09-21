import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'screens/cctv/cctv_camera_screen.dart';
import 'firebase_options.dart';
import 'screens/officer/ai_test_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/cctv/cctv_device_setup_screen.dart';
import 'screens/officer/satellite_test_screen.dart';
import 'services/offline_storage_service.dart';
import 'services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage must be ready before the app starts.
  await OfflineStorageService.init();

  // Start AEGIS immediately.
  runApp(const AegisAI());

  // Initialize cloud services in the background.
  _initializeServices();
}

Future<void> _initializeServices() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );

    await Supabase.initialize(
      url: 'https://cdkwzxjneqxsroswkqtc.supabase.co',
      anonKey: 'sb_publishable_W7lUTqOs_PRppCZGRLrvMg_-FkTkTLz',
    );

    await NotificationService().initialize();

    SyncService.start();
  } catch (e) {
    debugPrint('Cloud services unavailable: $e');

    // AEGIS continues in offline mode.
  }
}

class AegisAI extends StatelessWidget {
  const AegisAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false,
  title: "AEGIS AI",

  theme: ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.blue,
  ),

  
  home: const SplashScreen(),

  routes: {
    "/login": (context) => const LoginScreen(),

    "/ai-test": (context) =>
        const AITestScreen(),

    "/cctv-setup": (context) =>
        const CctvDeviceSetupScreen(),

    "/satellite-test": (context) =>
        const SatelliteTestScreen(),
  },
);
  }
}