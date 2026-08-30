import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../services/webrtc_service.dart';
import 'dart:async';
import 'dart:typed_data';

import '../../services/cctv_person_detector.dart';
import '../../widgets/person_detection_overlay.dart';

class CctvLiveScreen extends StatefulWidget {
  final String deviceId;
  final String cameraName;

  const CctvLiveScreen({
    super.key,
    required this.deviceId,
    required this.cameraName,
  });

  @override
  State<CctvLiveScreen> createState() =>
      _CctvLiveScreenState();
}

class _CctvLiveScreenState
    extends State<CctvLiveScreen> {

  final WebRtcService _webRtcService =
      WebRtcService();

  final RTCVideoRenderer _remoteRenderer =
      RTCVideoRenderer();

  final CctvPersonDetector _personDetector =
      CctvPersonDetector();

  MediaStreamTrack? _remoteVideoTrack;

  Timer? _detectionTimer;

  List<PersonDetection> _personDetections = [];

  bool _detectionRunning = false;
  bool _aiReady = false;

  bool _isLoading = true;
  bool _isConnected = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Initialize video renderer
      await _remoteRenderer.initialize();

      // Connect to CCTV WebRTC stream
      await _webRtcService.receiveBroadcast(
        deviceId: widget.deviceId,

        onRemoteStream: (
  MediaStream stream,
) {
  _remoteRenderer.srcObject = stream;

  final videoTracks =
      stream.getVideoTracks();

  if (videoTracks.isNotEmpty) {
    _remoteVideoTrack =
        videoTracks.first;

    debugPrint(
      'REMOTE VIDEO TRACK READY: '
      '${_remoteVideoTrack!.id}',
    );
  }

  if (!mounted) return;

  setState(() {
    _isConnected = true;
    _isLoading = false;
    _errorMessage = '';
  });

  _startPersonDetection();
},
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isConnected = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
void dispose() {
  _detectionTimer?.cancel();

  _personDetector.dispose();

  _remoteRenderer.srcObject = null;
  _remoteRenderer.dispose();

  _webRtcService.dispose();

  super.dispose();
}
  

Future<void> _startPersonDetection() async {
  if (_detectionTimer != null) {
    return;
  }

  try {
    await _personDetector.initialize();

    if (!mounted) return;

    setState(() {
      _aiReady = true;
    });
  } catch (e) {
    debugPrint(
      'YOLO initialization error: $e',
    );
    return;
  }

  // Run detection about 5 times per second.
  _detectionTimer = Timer.periodic(
    const Duration(milliseconds: 200),
    (_) {
      _runPersonDetection();
    },
  );
}
Future<void> _runPersonDetection() async {
  if (!_aiReady ||
      _detectionRunning ||
      !_isConnected ||
      _remoteVideoTrack == null) {
    return;
  }

  _detectionRunning = true;

  try {
    final ByteBuffer buffer =
        await _remoteVideoTrack!.captureFrame();

    final Uint8List bytes =
        buffer.asUint8List();

    if (bytes.isEmpty) {
      return;
    }

    final detections =
        await _personDetector
            .detectPeople(bytes);

    if (!mounted) return;

    setState(() {
      _personDetections = detections;
    });
  } catch (e) {
    debugPrint(
      'Person detection error: $e',
    );
  } finally {
    _detectionRunning = false;
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: Text(widget.cameraName),
        backgroundColor:
            const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // =====================================================
            // LIVE CCTV VIDEO
            // =====================================================

            Container(
              width: double.infinity,
              height: 240,

              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius:
                    BorderRadius.circular(16),
              ),

              clipBehavior: Clip.antiAlias,

              child: Stack(
                children: [

                  // REAL LIVE VIDEO
                  if (_isConnected)
  Positioned.fill(
    child: Stack(
      fit: StackFit.expand,
      children: [
        RTCVideoView(
          _remoteRenderer,
          objectFit:
              RTCVideoViewObjectFit
                  .RTCVideoViewObjectFitCover,
        ),

        PersonDetectionOverlay(
          detections: _personDetections,
        ),
      ],
    ),
  )

                  // CONNECTING
                  else if (_isLoading)
                    const Center(
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [

                          CircularProgressIndicator(
                            color: Colors.white,
                          ),

                          SizedBox(height: 15),

                          Text(
                            'Connecting to CCTV...',
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    )

                  // ERROR / WAITING
                  else
                    Center(
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [

                          const Icon(
                            Icons.videocam_off,
                            color: Colors.white54,
                            size: 60,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            _errorMessage.isNotEmpty
                                ? 'Unable to connect'
                                : 'Waiting for video...',
                            style: const TextStyle(
                              color: Colors.white54,
                            ),
                          ),

                          if (_errorMessage.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.all(12),
                              child: Text(
                                _errorMessage,
                                textAlign:
                                    TextAlign.center,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // LIVE BADGE
                  Positioned(
                    top: 12,
                    left: 12,

                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),

                      decoration: BoxDecoration(
                        color: _isConnected
                            ? Colors.red
                            : Colors.grey,
                        borderRadius:
                            BorderRadius.circular(6),
                      ),

                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [

                          const Icon(
                            Icons.circle,
                            size: 10,
                            color: Colors.white,
                          ),

                          const SizedBox(width: 6),

                          Text(
                            _isConnected
                                ? 'LIVE'
                                : 'CONNECTING',
                            style:
                                const TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'CCTV Camera Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _statusCard(
              icon: Icons.videocam,
              title: 'Camera',
              value: _isConnected
                  ? 'Live'
                  : _isLoading
                      ? 'Connecting...'
                      : 'Waiting for video...',
              color: _isConnected
                  ? Colors.green
                  : Colors.orange,
            ),

            const SizedBox(height: 10),

            _statusCard(
  icon: Icons.psychology,
  title: 'AI Human Detection',
  value: _aiReady
      ? 'ACTIVE'
      : 'INITIALIZING',
  color: _aiReady
      ? Colors.green
      : Colors.orange,
),

            const SizedBox(height: 10),

            _statusCard(
              icon: Icons.people,
              title: 'People Detected',
              value: _aiReady
    ? '${_personDetections.length}'
    : '—',
color: _personDetections.isNotEmpty
    ? Colors.red
    : Colors.grey,
            ),

            const Spacer(),

            Center(
              child: Text(
                _isConnected
                    ? 'Monitoring live CCTV camera.'
                    : 'Waiting for CCTV video connection.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _statusCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              color.withOpacity(0.12),
          child: Icon(
            icon,
            color: color,
          ),
        ),

        title: Text(title),

        trailing: Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }
}