import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../services/webrtc_service.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final WebRtcService _webRtcService =
      WebRtcService();

  final RTCVideoRenderer _localRenderer =
      RTCVideoRenderer();

  String? _streamId;

  bool _starting = false;
  bool _isLive = false;
  bool _cameraReady = false;

  Position? _position;
String _address = '';

  @override
  void initState() {
    super.initState();
    _initializeRenderer();
  }

  Future<void> _initializeRenderer() async {
    await _localRenderer.initialize();

    if (mounted) {
      setState(() {});
    }
  }

  Future<Position> _getLocation() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable GPS.',
      );
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'Location permission was denied.',
      );
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Enable it from Settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<String> _getAddressFromLocation(
  Position position,
) async {
  try {
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty) {
      return 'Address unavailable';
    }

    final place = placemarks.first;

    final parts = <String>[
      if (place.name != null &&
          place.name!.trim().isNotEmpty)
        place.name!.trim(),

      if (place.street != null &&
          place.street!.trim().isNotEmpty &&
          place.street != place.name)
        place.street!.trim(),

      if (place.subLocality != null &&
          place.subLocality!.trim().isNotEmpty)
        place.subLocality!.trim(),

      if (place.locality != null &&
          place.locality!.trim().isNotEmpty)
        place.locality!.trim(),

      if (place.subAdministrativeArea != null &&
          place.subAdministrativeArea!.trim().isNotEmpty)
        place.subAdministrativeArea!.trim(),

      if (place.administrativeArea != null &&
          place.administrativeArea!.trim().isNotEmpty)
        place.administrativeArea!.trim(),

      if (place.postalCode != null &&
          place.postalCode!.trim().isNotEmpty)
        place.postalCode!.trim(),

      if (place.country != null &&
          place.country!.trim().isNotEmpty)
        place.country!.trim(),
    ];

    return parts.toSet().join(', ');
  } catch (e) {
    debugPrint('Reverse geocoding error: $e');
    return 'Address unavailable';
  }
}

  Future<String> _getCitizenName() async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'Citizen';
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      if (data != null) {
        final name = data['name']?.toString();

        if (name != null && name.trim().isNotEmpty) {
          return name;
        }
      }
    } catch (_) {}

    return 'Citizen';
  }

  Future<void> _startLiveStream() async {
    if (_starting || _isLive) {
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please login before starting a live stream.',
      );
      return;
    }

    setState(() {
      _starting = true;
    });

    DocumentReference<Map<String, dynamic>>?
        streamRef;

    try {
      // 1. Get location
      final position = await _getLocation();

// Convert GPS coordinates into a readable address.
final address =
    await _getAddressFromLocation(position);

// Get citizen name.
final citizenName =
    await _getCitizenName();

      // 3. Create unique stream ID
      streamRef = _firestore
          .collection('citizenLiveStreams')
          .doc();

      final streamId = streamRef.id;

      // 4. Create stream metadata
      await streamRef.set({
        'streamId': streamId,
        'citizenId': user.uid,
        'citizenName': citizenName,
        'status': 'starting',
        'latitude': position.latitude,
'longitude': position.longitude,
'address': address,
        'startedAt':
            FieldValue.serverTimestamp(),
      });

      // 5. Start camera
      final mediaStream =
          await _webRtcService.startCameraStream();

      if (!_localRenderer
          .renderVideo) {
        _localRenderer.srcObject =
            mediaStream;
      } else {
        _localRenderer.srcObject =
            mediaStream;
      }

      if (mounted) {
        setState(() {
          _cameraReady = true;
        });
      }

      // 6. Start WebRTC broadcast
      await _webRtcService
          .startCitizenBroadcast(streamId);

      // 7. Mark stream as live
      await streamRef.update({
        'status': 'live',
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _streamId = streamId;
        _position = position;
        _address = address;
        _isLive = true;
        _starting = false;
      });

      _showMessage(
        'Live stream started successfully.',
      );
    } catch (e) {
      if (streamRef != null) {
        try {
          await streamRef.delete();
        } catch (_) {}
      }

      try {
        await _webRtcService.dispose();
      } catch (_) {}

      if (!mounted) {
        return;
      }

      setState(() {
        _starting = false;
        _isLive = false;
        _cameraReady = false;
      });

      _showMessage(
        'Unable to start live stream: $e',
      );
    }
  }

  Future<void> _stopLiveStream() async {
    final streamId = _streamId;

    if (streamId == null) {
      return;
    }

    setState(() {
      _starting = true;
    });

    try {
      await _webRtcService
          .stopCitizenBroadcast(streamId);

      await _firestore
          .collection('citizenLiveStreams')
          .doc(streamId)
          .update({
        'status': 'ended',
        'endedAt':
            FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        'Error stopping citizen stream: $e',
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _streamId = null;
      _position = null;
      _isLive = false;
      _starting = false;
      _cameraReady = false;
    });

    _localRenderer.srcObject = null;

    _showMessage(
      'Live stream ended.',
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  void dispose() {
    final streamId = _streamId;

    if (streamId != null) {
      unawaited(
        _webRtcService
            .stopCitizenBroadcast(streamId),
      );

      unawaited(
        _firestore
            .collection('citizenLiveStreams')
            .doc(streamId)
            .update({
          'status': 'ended',
          'endedAt':
              FieldValue.serverTimestamp(),
        })
            .catchError((_) {}),
      );
    } else {
      unawaited(
        _webRtcService.dispose(),
      );
    }

    _localRenderer.srcObject = null;
    unawaited(_localRenderer.dispose());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isLive) {
          await _stopLiveStream();
        }

        return true;
      },
      child: Scaffold(
        backgroundColor:
            const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text(
            'Citizen Live Stream',
          ),
          backgroundColor:
              const Color(0xFF0B3D91),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Emergency Live Stream',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Share your camera live with the emergency response team.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 20),

              // CAMERA PREVIEW
              Container(
                width: double.infinity,
                height: 420,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                clipBehavior:
                    Clip.antiAlias,
                child: _cameraReady
                    ? RTCVideoView(
                        _localRenderer,
                        mirror: false,
                        objectFit:
                            RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.videocam_off,
                          color: Colors.white54,
                          size: 70,
                        ),
                      ),
              ),

              const SizedBox(height: 18),

              // STATUS
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isLive
                      ? Colors.green
                          .withValues(alpha: 0.12)
                      : Colors.grey
                          .withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isLive
                          ? Icons.circle
                          : Icons.circle_outlined,
                      color: _isLive
                          ? Colors.green
                          : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _starting
                            ? 'Starting live stream...'
                            : _isLive
                                ? 'LIVE — Response team can view your stream'
                                : 'Not streaming',
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // LOCATION
              if (_position != null)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.location_on,
              color: Colors.red,
            ),
            SizedBox(width: 10),
            Text(
              'Your Location',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Text(
          _address.isNotEmpty
              ? _address
              : 'Finding your address...',
          style: const TextStyle(
            fontSize: 16,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'GPS: ${_position!.latitude.toStringAsFixed(6)}, '
          '${_position!.longitude.toStringAsFixed(6)}',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
      ],
    ),
  ),

              const SizedBox(height: 22),

              // START / STOP BUTTON
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _starting
                      ? null
                      : (_isLive
                          ? _stopLiveStream
                          : _startLiveStream),
                  icon: Icon(
                    _isLive
                        ? Icons.stop_circle
                        : Icons.videocam,
                  ),
                  label: Text(
                    _starting
                        ? 'PLEASE WAIT...'
                        : (_isLive
                            ? 'STOP LIVE STREAM'
                            : 'START LIVE STREAM'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: _isLive
                        ? Colors.red
                        : const Color(
                            0xFF0B3D91,
                          ),
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                              14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Important',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Only start a live stream during an emergency or when you need to show the response team what is happening around you.',
                style: TextStyle(
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}