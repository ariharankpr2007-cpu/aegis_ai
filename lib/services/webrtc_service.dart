import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRtcService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  RTCPeerConnection? _peerConnection;

  MediaStream? _localStream;
  MediaStream? _remoteStream;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _callSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _candidateSubscription;

  bool _remoteDescriptionSet = false;
  final List<RTCIceCandidate> _pendingCandidates = [];

  final Map<String, dynamic> _configuration = {
  'iceServers': [
    {
      'urls': [
        'stun:stun.l.google.com:19302',
      ],
    },
    {
      'urls': [
        'turn:free.expressturn.com:3478?transport=udp',
        'turn:free.expressturn.com:3478?transport=tcp',
      ],
      'username': '000000002103295959',
      'credential': '60MUih+58LJkiOtSq9/+SZ7f3vQ=',
    },
  ],
};

  // ============================================================
  // CCTV PHONE
  // START CAMERA STREAM
  // ============================================================

  Future<MediaStream> startCameraStream() async {
    if (_localStream != null) {
      return _localStream!;
    }

    final constraints = {
      'audio': false,
      'video': {
        'facingMode': 'environment',
        'width': 1280,
        'height': 720,
      },
    };

    _localStream =
        await navigator.mediaDevices.getUserMedia(
      constraints,
    );

    return _localStream!;
  }

  // ============================================================
  // DELETE OLD ICE CANDIDATES
  // ============================================================

  Future<void> _deleteCandidates(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // ============================================================
  // CCTV PHONE
  // START BROADCAST
  // ============================================================

  Future<void> startBroadcast(
  String deviceId, {
  String collection = 'cctvCalls',
}) async {
    await _cleanupConnectionOnly();

    _remoteDescriptionSet = false;

    final callRef =
    _firestore.collection(collection).doc(deviceId);

    // Clear old connection data
    await _deleteCandidates(
      callRef.collection('offerCandidates'),
    );

    await _deleteCandidates(
      callRef.collection('answerCandidates'),
    );

    _peerConnection =
        await createPeerConnection(_configuration);
        _peerConnection!.onConnectionState =
    (RTCPeerConnectionState state) {
  print(
    'CCTV CONNECTION STATE: $state',
  );
};

_peerConnection!.onIceConnectionState =
    (RTCIceConnectionState state) {
  print(
    'CCTV ICE STATE: $state',
  );
};

    _localStream ??=
        await startCameraStream();

    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(
        track,
        _localStream!,
      );
    }

    // ==========================================================
    // SEND CCTV ICE CANDIDATES
    // ==========================================================

    _peerConnection!.onIceCandidate =
        (RTCIceCandidate candidate) async {
      if (candidate.candidate != null) {
        await callRef
            .collection('offerCandidates')
            .add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex':
              candidate.sdpMLineIndex,
        });
      }
    };

    // ==========================================================
    // CREATE OFFER
    // ==========================================================

    final offer =
        await _peerConnection!.createOffer();

    await _peerConnection!
        .setLocalDescription(offer);

    await callRef.set({
      'offer': {
        'type': offer.type,
        'sdp': offer.sdp,
      },
      'answer': null,
      'status': 'waiting',
      'createdAt':
          FieldValue.serverTimestamp(),
    });

    // ==========================================================
    // LISTEN FOR OFFICER ANSWER
    // ==========================================================

    _callSubscription =
    callRef.snapshots().listen(
  (snapshot) async {
    final data = snapshot.data();

    if (data == null ||
        _peerConnection == null) {
      return;
    }

    if (data['answer'] != null &&
        !_remoteDescriptionSet) {
      final answer = data['answer'];

      if (answer['sdp'] == null ||
          answer['type'] == null) {
        return;
      }

      try {
        print('CCTV: Setting officer answer...');

        await _peerConnection!
            .setRemoteDescription(
          RTCSessionDescription(
            answer['sdp'],
            answer['type'],
          ),
        );

        _remoteDescriptionSet = true;

        print(
          'CCTV: Remote description set successfully',
        );

        // Add ICE candidates that arrived early
        for (final candidate
            in _pendingCandidates) {
          try {
            await _peerConnection!
                .addCandidate(candidate);

            print(
              'CCTV: Added pending ICE candidate',
            );
          } catch (e) {
            print(
              'CCTV pending candidate error: $e',
            );
          }
        }

        _pendingCandidates.clear();
      } catch (e) {
        print(
          'CCTV answer error: $e',
        );
      }
    }
  },
);

    // ==========================================================
    // LISTEN FOR OFFICER ICE CANDIDATES
    // ==========================================================

    _candidateSubscription =
    callRef
        .collection('answerCandidates')
        .snapshots()
        .listen(
  (snapshot) async {
    for (final change
        in snapshot.docChanges) {
      if (change.type !=
          DocumentChangeType.added) {
        continue;
      }

      final data = change.doc.data();

      if (data == null ||
          _peerConnection == null) {
        continue;
      }

      final candidate =
          RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );

      // IMPORTANT:
      // If answer is not set yet, save candidate
      if (!_remoteDescriptionSet) {
        print(
          'CCTV: Saving ICE candidate until answer is ready',
        );

        _pendingCandidates.add(
          candidate,
        );

        continue;
      }

      try {
        await _peerConnection!
            .addCandidate(candidate);

        print(
          'CCTV: Added officer ICE candidate',
        );
      } catch (e) {
        print(
          'CCTV candidate error: $e',
        );
      }
    }
  },
);
  }

  // ============================================================
  // OFFICER
  // START WATCHING CCTV
  // ============================================================

  Future<void> startWatching(
  String deviceId,
  Function(MediaStream stream) onRemoteStream, {
  String collection = 'cctvCalls',
}) async {
    await _cleanupConnectionOnly();

    _remoteDescriptionSet = false;

    final callRef =
    _firestore.collection(collection).doc(deviceId);

    final callSnapshot =
        await callRef.get();

    if (!callSnapshot.exists) {
      throw Exception(
        'CCTV stream not found',
      );
    }

    final callData =
        callSnapshot.data();

    if (callData == null ||
        callData['offer'] == null) {
      throw Exception(
        'CCTV offer not available',
      );
    }

    final offer = callData['offer'];

    if (offer['sdp'] == null ||
        offer['type'] == null) {
      throw Exception(
        'Invalid CCTV offer',
      );
    }

    // ==========================================================
    // CREATE OFFICER PEER CONNECTION
    // ==========================================================

    _peerConnection =
        await createPeerConnection(_configuration);
        _peerConnection!.onConnectionState =
    (RTCPeerConnectionState state) {
  print(
    'OFFICER CONNECTION STATE: $state',
  );
};

_peerConnection!.onIceConnectionState =
    (RTCIceConnectionState state) {
  print(
    'OFFICER ICE STATE: $state',
  );
};

    // ==========================================================
    // RECEIVE VIDEO
    // ==========================================================

    _peerConnection!.onTrack =
        (RTCTrackEvent event) {
      print(
        'Officer received track: '
        '${event.track.kind}',
      );

      if (event.streams.isNotEmpty) {
        _remoteStream =
            event.streams.first;

        onRemoteStream(
          _remoteStream!,
        );
      }
    };

    // ==========================================================
    // SEND OFFICER ICE CANDIDATES
    // ==========================================================

    _peerConnection!.onIceCandidate =
        (RTCIceCandidate candidate) async {
      if (candidate.candidate != null) {
        await callRef
            .collection('answerCandidates')
            .add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex':
              candidate.sdpMLineIndex,
        });
      }
    };

    // ==========================================================
    // SET CCTV OFFER
    // ==========================================================

    await _peerConnection!
        .setRemoteDescription(
      RTCSessionDescription(
        offer['sdp'],
        offer['type'],
      ),
    );

    // ==========================================================
    // LISTEN FOR CCTV ICE CANDIDATES
    // ==========================================================

    _candidateSubscription =
        callRef
            .collection('offerCandidates')
            .snapshots()
            .listen(
      (snapshot) async {
        for (final change
            in snapshot.docChanges) {
          if (change.type !=
              DocumentChangeType.added) {
            continue;
          }

          final data = change.doc.data();

          if (data == null ||
              _peerConnection == null) {
            continue;
          }

          try {
            final candidate =
                RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            );

            await _peerConnection!
                .addCandidate(candidate);
          } catch (e) {
            print(
              'Officer candidate error: $e',
            );
          }
        }
      },
    );

    // ==========================================================
    // CREATE ANSWER
    // ==========================================================

    final answer =
        await _peerConnection!
            .createAnswer();

    await _peerConnection!
        .setLocalDescription(answer);

    // ==========================================================
    // SEND ANSWER TO CCTV
    // ==========================================================

    await callRef.update({
      'answer': {
        'type': answer.type,
        'sdp': answer.sdp,
      },
      'status': 'connected',
    });
  }
  // ================= CITIZEN LIVE STREAM =================

Future<void> startCitizenBroadcast(String streamId) async {
  await startBroadcast(
    streamId,
    collection: 'citizenLiveCalls',
  );
}

Future<void> watchCitizenBroadcast(
  String streamId,
  Function(MediaStream stream) onRemoteStream,
) async {
  await startWatching(
    streamId,
    onRemoteStream,
    collection: 'citizenLiveCalls',
  );
}

Future<void> stopCitizenBroadcast(String streamId) async {
  await stopBroadcast(
    streamId,
    collection: 'citizenLiveCalls',
  );
}

  // ============================================================
  // OLD METHOD COMPATIBILITY
  // ============================================================

  Future<void> receiveBroadcast({
    required String deviceId,
    required Function(MediaStream stream)
        onRemoteStream,
  }) async {
    await startWatching(
      deviceId,
      onRemoteStream,
    );
  }

  // ============================================================
  // STOP OFFICER WATCHING
  // ============================================================

  Future<void> stop() async {
    await _cleanupConnectionOnly();

    _remoteStream = null;
  }

  // ============================================================
  // STOP CCTV BROADCAST
  // ============================================================

  Future<void> stopBroadcast(
  String deviceId, {
  String collection = 'cctvCalls',
}) async {
    await _cleanupConnectionOnly();

    for (final track
        in _localStream?.getTracks() ?? []) {
      track.stop();
    }

    _localStream = null;
    _remoteStream = null;

    final callRef =
    _firestore.collection(collection).doc(deviceId);

    await _deleteCandidates(
      callRef.collection('offerCandidates'),
    );

    await _deleteCandidates(
      callRef.collection('answerCandidates'),
    );

    await callRef.delete().catchError(
      (_) {},
    );
  }

  // ============================================================
  // CLEANUP CONNECTION ONLY
  // ============================================================

  Future<void> _cleanupConnectionOnly() async {
    await _callSubscription?.cancel();
    await _candidateSubscription?.cancel();

    _callSubscription = null;
    _candidateSubscription = null;

    await _peerConnection?.close();

    _peerConnection = null;
    _remoteDescriptionSet = false;
  }

  // ============================================================
  // DISPOSE EVERYTHING
  // ============================================================

  Future<void> dispose() async {
    await _cleanupConnectionOnly();

    for (final track
        in _localStream?.getTracks() ?? []) {
      track.stop();
    }

    _localStream = null;
    _remoteStream = null;
  }
}