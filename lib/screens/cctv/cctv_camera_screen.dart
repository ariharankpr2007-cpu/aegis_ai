
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/webrtc_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';

class CctvCameraScreen extends StatefulWidget {
  final String deviceId;
  final String cameraName;

  const CctvCameraScreen({
    super.key,
    required this.deviceId,
    required this.cameraName,
  });

  @override
  State<CctvCameraScreen> createState() =>
      _CctvCameraScreenState();
}

class _CctvCameraScreenState extends State<CctvCameraScreen> {
  final WebRtcService _webRtcService = WebRtcService();

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
    @override
void initState() {
  super.initState();
  _initializeRenderer();
}
Future<void> _logout() async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Logout CCTV?'),
        content: const Text(
          'Are you sure you want to logout? The CCTV camera will be stopped.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('LOGOUT'),
          ),
        ],
      );
    },
  );

  if (shouldLogout != true) return;

  try {
    if (_isLive) {
      await _stopCctv();
    }

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logout error: $e'),
      ),
    );
  }
}

Future<void> _initializeRenderer() async {
  await _localRenderer.initialize();
}

  bool _isCameraInitialized = false;
  bool _isLive = false;
  bool _isLoading = false;

  @override
void dispose() {
  _localRenderer.srcObject = null;
  _localRenderer.dispose();

  _webRtcService.stopBroadcast(widget.deviceId);

  FirebaseFirestore.instance
      .collection('cctvDevices')
      .doc(widget.deviceId)
      .update({
    'status': 'offline',
    'peopleCount': 0,
    'lastActive': FieldValue.serverTimestamp(),
  }).catchError((_) {});

  super.dispose();
}
  Future<void> _updateCameraStatus(String status) async {
  await FirebaseFirestore.instance
      .collection('cctvDevices')
      .doc(widget.deviceId)
      .update({
    'status': status,
    'lastSeen': FieldValue.serverTimestamp(),
  });
}

  Future<void> _startCctv() async {
  if (_isLoading) return;

  setState(() {
    _isLoading = true;
  });

  try {
    final stream =
        await _webRtcService.startCameraStream();

    _localRenderer.srcObject = stream;

    await _webRtcService.startBroadcast(
      widget.deviceId,
    );

    await FirebaseFirestore.instance
        .collection('cctvDevices')
        .doc(widget.deviceId)
        .update({
      'status': 'online',
      'peopleCount': 0,
      'lastActive': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    setState(() {
      _isCameraInitialized = true;
      _isLive = true;
      _isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Camera error: $e'),
      ),
    );
  }
}

  Future<void> _stopCctv() async {
  try {
    await _webRtcService.stopBroadcast(
      widget.deviceId,
    );

    _localRenderer.srcObject = null;

    await FirebaseFirestore.instance
        .collection('cctvDevices')
        .doc(widget.deviceId)
        .update({
      'status': 'offline',
      'peopleCount': 0,
      'lastActive': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    setState(() {
      _isCameraInitialized = false;
      _isLive = false;
    });
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Stop camera error: $e'),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
  title: Text(widget.cameraName),
  backgroundColor: const Color(0xFF087F5B),
  foregroundColor: Colors.white,

  actions: [
    IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Logout',
      onPressed: _logout,
    ),
  ],
),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Container(
              width: double.infinity,
              height: 360,

              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius:
                    BorderRadius.circular(16),
              ),

              clipBehavior: Clip.antiAlias,

              child: _isCameraInitialized
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
  RTCVideoView(
    _localRenderer,
    objectFit:
        RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
  ),

  if (_isLive)
    Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 10,
              color: Colors.white,
            ),
            SizedBox(width: 6),
            Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ),
],
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.videocam_off,
                            color: Colors.white54,
                            size: 60,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Camera is offline',
                            style: TextStyle(
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Icon(
                  _isLive
                      ? Icons.circle
                      : Icons.circle_outlined,
                  color: _isLive
                      ? Colors.green
                      : Colors.grey,
                  size: 14,
                ),

                const SizedBox(width: 8),

                Text(
                  _isLive
                      ? 'CCTV Camera Active'
                      : 'CCTV Camera Offline',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              _isLive
                  ? 'Camera is active and registered as ${widget.cameraName}'
                  : 'Start the camera to activate CCTV mode',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 54,

              child: FilledButton.icon(
                onPressed: _isLoading
                    ? null
                    : _isLive
                        ? _stopCctv
                        : _startCctv,

                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isLive
                            ? Icons.stop
                            : Icons.play_arrow,
                      ),

                label: Text(
                  _isLoading
                      ? 'STARTING CAMERA...'
                      : _isLive
                          ? 'STOP CCTV'
                          : 'START CCTV CAMERA',
                ),

                style: FilledButton.styleFrom(
                  backgroundColor:
                      _isLive
                          ? Colors.red
                          : const Color(
                              0xFF087F5B,
                            ),
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}