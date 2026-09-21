import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/webrtc_service.dart';

class CitizenLiveViewerScreen extends StatefulWidget {
  final String streamId;
  final String citizenName;
  final String address;
  final dynamic latitude;
  final dynamic longitude;

  const CitizenLiveViewerScreen({
    super.key,
    required this.streamId,
    required this.citizenName,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<CitizenLiveViewerScreen> createState() =>
      _CitizenLiveViewerScreenState();
}

class _CitizenLiveViewerScreenState
    extends State<CitizenLiveViewerScreen> {
  final WebRtcService _webRtcService = WebRtcService();

  final RTCVideoRenderer _remoteRenderer =
      RTCVideoRenderer();

  bool _isLoading = true;
  bool _isConnected = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _connectToCitizenStream();
  }

  Future<void> _openLocation() async {
  final latitude =
      double.tryParse(widget.latitude.toString());

  final longitude =
      double.tryParse(widget.longitude.toString());

  if (latitude == null || longitude == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location coordinates unavailable.'),
      ),
    );
    return;
  }

  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1'
    '&query=$latitude,$longitude',
  );

  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  } else {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open maps.'),
      ),
    );
  }
}

  Future<void> _connectToCitizenStream() async {
    try {
      await _remoteRenderer.initialize();

      await _webRtcService.watchCitizenBroadcast(
        widget.streamId,
        (MediaStream stream) {
          _remoteRenderer.srcObject = stream;

          if (!mounted) return;

          setState(() {
            _isConnected = true;
            _isLoading = false;
            _errorMessage = '';
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Citizen live stream connection error: $e',
      );

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
    _remoteRenderer.srcObject = null;
    _remoteRenderer.dispose();

    _webRtcService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text(
          'Citizen Live Stream',
        ),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ============================
          // LIVE VIDEO
          // ============================

          Container(
            width: double.infinity,
            height: 360,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (_isConnected)
                  Positioned.fill(
                    child: RTCVideoView(
                      _remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit
                              .RTCVideoViewObjectFitCover,
                    ),
                  )
                else if (_isLoading)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.white,
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Connecting to citizen...',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(20),
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
                          const Text(
                            'Unable to connect',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 17,
                            ),
                          ),
                          if (_errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                // LIVE BADGE
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _isConnected
                          ? Colors.red
                          : Colors.grey,
                      borderRadius:
                          BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.circle,
                          color: Colors.white,
                          size: 9,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isConnected
                              ? 'LIVE'
                              : 'CONNECTING',
                          style: const TextStyle(
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

          // ============================
          // CITIZEN INFORMATION
          // ============================

          const Text(
            'Citizen Information',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoRow(
                    Icons.person,
                    'Citizen',
                    widget.citizenName,
                  ),

                  const Divider(height: 25),

                  _infoRow(
                    Icons.location_on,
                    'Location',
                    widget.address,
                  ),

                  const Divider(height: 25),

                  _infoRow(
                    Icons.gps_fixed,
                    'GPS',
                    '${widget.latitude}, '
                    '${widget.longitude}',
                  ),
                  const SizedBox(height: 18),

SizedBox(
  width: double.infinity,
  height: 48,
  child: ElevatedButton.icon(
    onPressed: _openLocation,
    icon: const Icon(Icons.map),
    label: const Text(
      'OPEN LOCATION ON MAP',
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0B3D91),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),
),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ============================
          // CONNECTION STATUS
          // ============================

          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _isConnected
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
                child: Icon(
                  _isConnected
                      ? Icons.wifi
                      : Icons.sync,
                  color: _isConnected
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
              title: const Text(
                'Stream Connection',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Text(
                _isConnected
                    ? 'CONNECTED'
                    : _isLoading
                        ? 'CONNECTING'
                        : 'DISCONNECTED',
                style: TextStyle(
                  color: _isConnected
                      ? Colors.green
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            _isConnected
                ? 'Monitoring citizen emergency stream.'
                : 'Waiting for citizen video connection.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor:
              const Color(0xFF0B3D91)
                  .withValues(alpha: 0.10),
          child: Icon(
            icon,
            color: const Color(0xFF0B3D91),
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}