import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class AICameraScreen extends StatefulWidget {
  const AICameraScreen({super.key});

  @override
  State<AICameraScreen> createState() => _AICameraScreenState();
}

class _AICameraScreenState extends State<AICameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  bool _isInitializing = true;
  bool _cameraError = false;

  int _selectedCamera = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('No camera available');
      }

      _cameraController = CameraController(
        _cameras[_selectedCamera],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('Camera initialization error: $e');

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _cameraError = true;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    setState(() {
      _isInitializing = true;
    });

    await _cameraController?.dispose();

    _selectedCamera =
        _selectedCamera == 0 ? 1 : 0;

    try {
      _cameraController = CameraController(
        _cameras[_selectedCamera],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('Camera switch error: $e');

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _cameraError = true;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF031B49),
      body: SafeArea(
        child: Stack(
          children: [
            // =====================================================
            // CAMERA PREVIEW
            // =====================================================

            Positioned.fill(
              child: _buildCameraPreview(),
            ),

            // =====================================================
            // TOP GRADIENT
            // =====================================================

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 130,
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xCC000000),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // =====================================================
            // TOP BAR
            // =====================================================

            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  _circleButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AEGIS AI CAMERA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'LIVE ANALYSIS',
                          style: TextStyle(
                            color: Color(0xFF4DA3FF),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _circleButton(
                    icon: Icons.flip_camera_ios_rounded,
                    onPressed: _switchCamera,
                  ),
                ],
              ),
            ),

            // =====================================================
            // AI STATUS
            // =====================================================

            Positioned(
              top: 82,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4DA3FF)
                        .withValues(alpha: 0.6),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LiveDot(),
                    SizedBox(width: 7),
                    Text(
                      'AI READY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =====================================================
            // BOTTOM PANEL
            // =====================================================

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4DA3FF),
        ),
      );
    }

    if (_cameraError ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return Container(
        color: const Color(0xFF031B49),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_photography_rounded,
                color: Colors.white54,
                size: 60,
              ),
              SizedBox(height: 12),
              Text(
                'Camera unavailable',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: CameraPreview(_cameraController!),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        22,
      ),
      decoration: BoxDecoration(
        color: const Color(0xF2031B49),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF4DA3FF)
                .withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // -----------------------------------------------------
          // AI STATUS
          // -----------------------------------------------------

          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF4DA3FF),
                size: 22,
              ),

              const SizedBox(width: 9),

              const Expanded(
                child: Text(
                  'AI Detection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'READY',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // -----------------------------------------------------
          // MODE BUTTONS
          // -----------------------------------------------------

          Row(
            children: [
              Expanded(
                child: _modeButton(
                  icon: Icons.videocam_rounded,
                  label: 'LIVE',
                  selected: true,
                  onTap: () {},
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _modeButton(
                  icon: Icons.thermostat_rounded,
                  label: 'THERMAL',
                  selected: false,
                  onTap: () {
                    _showComingSoon(
                      'AI-ESTIMATED THERMAL VIEW',
                    );
                  },
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _modeButton(
                  icon: Icons.radar_rounded,
                  label: 'RADAR',
                  selected: false,
                  onTap: () {
                    _showComingSoon(
                      'AI-SIMULATED RADAR VIEW',
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // -----------------------------------------------------
          // DETECTION SUMMARY
          // -----------------------------------------------------

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: Color(0xFF4DA3FF),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Waiting for AI detection...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFF1677FF)
              : Colors.white.withValues(alpha: 0.08),
          foregroundColor: Colors.white,
          elevation: selected ? 4 : 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF4DA3FF)
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title will be implemented next.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.greenAccent,
      ),
    );
  }
}