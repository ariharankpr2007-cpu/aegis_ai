import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cctv_camera_screen.dart';

class CctvDeviceSetupScreen extends StatefulWidget {
  const CctvDeviceSetupScreen({super.key});

  @override
  State<CctvDeviceSetupScreen> createState() =>
      _CctvDeviceSetupScreenState();
}

class _CctvDeviceSetupScreenState
    extends State<CctvDeviceSetupScreen> {
  final TextEditingController _cameraNameController =
      TextEditingController(
    text: 'AEGIS-CAM-01',
  );

  bool _isRegistering = false;

  @override
  void dispose() {
    _cameraNameController.dispose();
    super.dispose();
  }

  Future<void> _registerDevice() async {
    final cameraName =
        _cameraNameController.text.trim();

    if (cameraName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a camera name'),
        ),
      );
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      final deviceRef = FirebaseFirestore.instance
          .collection('cctvDevices')
          .doc();

      final deviceId = deviceRef.id;

      await deviceRef.set({
        'cameraName': cameraName,
        'status': 'offline',
        'peopleCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        'cctv_device_id',
        deviceId,
      );

      await prefs.setString(
        'cctv_camera_name',
        cameraName,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CctvCameraScreen(
            deviceId: deviceId,
            cameraName: cameraName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registration failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text('CCTV Device Setup'),
        backgroundColor: const Color(0xFF087F5B),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 30),

            const Icon(
              Icons.videocam,
              size: 80,
              color: Color(0xFF087F5B),
            ),

            const SizedBox(height: 20),

            const Text(
              'Register This Phone as CCTV',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'This Android phone will act as an AEGIS CCTV camera device.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 35),

            TextField(
              controller: _cameraNameController,
              decoration: const InputDecoration(
                labelText: 'Camera Name',
                hintText: 'Example: AEGIS-CAM-01',
                prefixIcon: Icon(Icons.videocam),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _isRegistering
                    ? null
                    : _registerDevice,
                icon: _isRegistering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.app_registration,
                      ),
                label: Text(
                  _isRegistering
                      ? 'REGISTERING...'
                      : 'REGISTER THIS PHONE',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF087F5B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}