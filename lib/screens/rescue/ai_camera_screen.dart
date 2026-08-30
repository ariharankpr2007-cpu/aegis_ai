import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/ai_service.dart';
import 'dart:math' as math;

class AICameraScreen extends StatefulWidget {
  const AICameraScreen({super.key});

  @override
  State<AICameraScreen> createState() => _AICameraScreenState();
}

class _AICameraScreenState
    extends State<AICameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  bool _initializing = true;
  String? _cameraError;

  String selectedMode = "NORMAL";
  String _aiResult = "No analysis yet";
bool _isAnalyzing = false;
bool _showDetectionBox = false;
double _boxX1 = 0.30;
double _boxY1 = 0.20;
double _boxX2 = 0.70;
double _boxY2 = 0.80;
double _radarX = 0.45;
double _radarY = 0.30;
List<Map<String, dynamic>> _radarDetections = [];
int _personConfidence = 0;
List<Map<String, dynamic>> _personDetections = [];
bool _showThermalEffect = false;
bool _showRadarEffect = false;
late AnimationController _radarAnimationController;
bool _isResultCollapsed = false;

  @override
void initState() {
  super.initState();

  _radarAnimationController = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 2),
);

  _initializeCamera();
}

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception("No camera found on this device.");
      }

      // Prefer the back camera.
      CameraDescription selectedCamera = _cameras.first;

      for (final camera in _cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _initializing = false;
        _cameraError = e.toString();
      });
    }
  }
  Future<void> _analyzeScene() async {
  if (_cameraController == null ||
    !_cameraController!.value.isInitialized) {
    return;
  }

  setState(() {
    _isAnalyzing = true;
    _aiResult = "Analyzing camera scene...";
  });

  try {
    final XFile image = await _cameraController!.takePicture();

    final result = await AIService().analyzeCameraFrame(
      File(image.path),
    );

    final summary = result["summary"] ?? "No summary available.";
    final risk = result["riskLevel"] ?? "LOW";
    final detections = result["detections"] as List? ?? [];
    final personDetections = detections
    .whereType<Map>()
    .map((d) => Map<String, dynamic>.from(d))
    .where(
      (d) => d["label"].toString().toLowerCase() == "person",
    )
    .toList();

if (personDetections.isNotEmpty) {
  final firstPerson = personDetections.first;

  final x1 =
      (firstPerson["x1"] as num?)?.toDouble() ?? 0.30;
  final y1 =
      (firstPerson["y1"] as num?)?.toDouble() ?? 0.20;
  final x2 =
      (firstPerson["x2"] as num?)?.toDouble() ?? 0.70;
  final y2 =
      (firstPerson["y2"] as num?)?.toDouble() ?? 0.80;

  setState(() {
    _personDetections = personDetections;
    _radarDetections = personDetections;

    _personConfidence =
        (firstPerson["confidence"] as num?)?.toInt() ?? 0;

    _boxX1 = x1;
    _boxY1 = y1;
    _boxX2 = x2;
    _boxY2 = y2;

    _radarX = (x1 + x2) / 2;
    _radarY = (y1 + y2) / 2;
  });
} else {
  setState(() {
    _personDetections = [];
_radarDetections = [];
    _showDetectionBox = false;
  });
}
    final detectionNames = detections
    .whereType<Map>()
    .map((d) => d["label"].toString())
    .toList();

    setState(() {
      _aiResult =
    "$summary\n\n"
    "⚠️ Risk Level: $risk\n"
    "🔎 Detections: ${detectionNames.isEmpty ? "None" : detectionNames.join(", ")}";
    _isResultCollapsed = true;
      _showDetectionBox = detections.any(
        (d) =>
            d is Map &&
            d["label"].toString().toLowerCase() == "person",
      );

      _isAnalyzing = false;
    });
  } catch (e) {
    setState(() {
      _isAnalyzing = false;
      _aiResult = "AI analysis failed.\n$e";
    });
  }
}

  @override
  void dispose() {
    _radarAnimationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF087F5B),
        foregroundColor: Colors.white,
        title: const Text("AI Rescue Camera"),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildCameraArea(),
          ),
          _buildModeControls(),
        ],
      ),
    );
  }

  Widget _buildCameraArea() {
    if (_initializing) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (_cameraError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white54,
                size: 70,
              ),
              const SizedBox(height: 15),
              const Text(
                "Unable to access camera",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _cameraError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _initializing = true;
                    _cameraError = null;
                  });

                  _initializeCamera();
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const Center(
        child: Text(
          "Camera not available",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),
        if (_showThermalEffect)
  Positioned.fill(
    child: IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.withValues(alpha: 0.25),
              Colors.purple.withValues(alpha: 0.20),
              Colors.red.withValues(alpha: 0.30),
            ],
          ),
        ),
      ),
    ),
  ),
  if (_showThermalEffect &&
    selectedMode == "THERMAL" &&
    _personDetections.isNotEmpty)
  ..._personDetections.map((person) {
    final x1 =
        (person["x1"] as num?)?.toDouble() ?? 0.30;
    final y1 =
        (person["y1"] as num?)?.toDouble() ?? 0.20;
    final x2 =
        (person["x2"] as num?)?.toDouble() ?? 0.70;
    final y2 =
        (person["y2"] as num?)?.toDouble() ?? 0.80;

    final confidence =
        (person["confidence"] as num?)?.toInt() ?? 0;

    return Positioned(
      left: x1 * MediaQuery.of(context).size.width,
      top: y1 * MediaQuery.of(context).size.height,
      width: (x2 - x1) *
          MediaQuery.of(context).size.width,
      height: (y2 - y1) *
          MediaQuery.of(context).size.height,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.red.withValues(alpha: 0.45),
              Colors.orange.withValues(alpha: 0.25),
              Colors.transparent,
            ],
            radius: 0.8,
          ),
          border: Border.all(
            color: Colors.orange,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.75),
              blurRadius: 25,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Text(
              "HEAT SIGNATURE $confidence%",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                backgroundColor: Colors.red,
              ),
            ),
          ),
        ),
      ),
    );
  }),
        if (_showDetectionBox && selectedMode == "AI")
  ..._personDetections.map((person) {
    final x1 =
        (person["x1"] as num?)?.toDouble() ?? 0.30;
    final y1 =
        (person["y1"] as num?)?.toDouble() ?? 0.20;
    final x2 =
        (person["x2"] as num?)?.toDouble() ?? 0.70;
    final y2 =
        (person["y2"] as num?)?.toDouble() ?? 0.80;

    final confidence =
        (person["confidence"] as num?)?.toInt() ?? 0;

    return Positioned(
      left: x1 * MediaQuery.of(context).size.width,
      top: y1 * MediaQuery.of(context).size.height,
      width: (x2 - x1) *
          MediaQuery.of(context).size.width,
      height: (y2 - y1) *
          MediaQuery.of(context).size.height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.red,
            width: 3,
          ),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Text(
              "PERSON $confidence%",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                backgroundColor: Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }),
  if (_showRadarEffect && _showDetectionBox)
  Positioned.fill(
    child: IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              Colors.green.withValues(alpha: 0.25),
              Colors.green.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
        child: CustomPaint(
          painter: _RadarPainter(
  detectionX: _radarX,
  detectionY: _radarY,
  sweepAngle: _radarAnimationController.value * 6.283185,
  animation: _radarAnimationController,
  confidence: _personConfidence,
  detections: _radarDetections,
),
        ),
      ),
    ),
  ),
  

        // Top information overlay
        Positioned(
          top: 15,
          left: 15,
          right: 15,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      "LIVE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  selectedMode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // AI mode information
        if (selectedMode == "AI")
          Positioned(
            left: 15,
            right: 15,
            bottom: 20,
            child: _aiStatusCard(),
          ),

        // Thermal information
        if (selectedMode == "THERMAL")
          Positioned(
            left: 15,
            right: 15,
            bottom: 20,
            child: _thermalStatusCard(),
          ),

        // Radar information
        if (selectedMode == "RADAR")
          Positioned(
            left: 15,
            right: 15,
            bottom: 20,
            child: _radarStatusCard(),
          ),
      ],
    );
  }

  Widget _aiStatusCard() {
  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.80),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: const Color(0xFF4DA3FF),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.psychology_rounded,
              color: Color(0xFF4DA3FF),
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              "AI DETECTION",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Spacer(),

IconButton(
  onPressed: () {
    setState(() {
      _isResultCollapsed = !_isResultCollapsed;
    });
  },
  icon: Icon(
    _isResultCollapsed
        ? Icons.keyboard_arrow_up
        : Icons.keyboard_arrow_down,
    color: Colors.white,
    size: 30,
  ),
),
          ],
        ),

        if (!_isResultCollapsed) ...[
  const SizedBox(height: 12),

        if (_isAnalyzing)
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF4DA3FF),
                ),
              ),
              SizedBox(width: 10),
              Text(
                "Analyzing scene...",
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          )
        else
          Text(
            _aiResult,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _analyzeScene,
            icon: const Icon(Icons.auto_awesome),
            label: const Text("Analyze Scene"),
          ),
        ),
        ],
      ],
    ),
  );
}

  Widget _thermalStatusCard() {
    return _statusCard(
      icon: Icons.thermostat_rounded,
      title: "AI-ESTIMATED THERMAL VIEW",
      text: "AI-estimated thermal view.\n"
    "This is a software visualization, not a real thermal camera.",
    );
  }

  Widget _radarStatusCard() {
    return _statusCard(
      icon: Icons.radar_rounded,
      title: "AI-SIMULATED RADAR VIEW",
      text:
    "AI-simulated radar view.\n"
    "Possible survivor — $_personConfidence% confidence.\n"
    "Estimated distance: 4.2 m",
    );
  }

  Widget _statusCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white24,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF4DA3FF),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        10,
        12,
        10,
        18,
      ),
      color: const Color(0xFF101010),
      child: Row(
        children: [
          _modeButton(
            "NORMAL",
            Icons.videocam_rounded,
          ),
          _modeButton(
            "AI",
            Icons.psychology_rounded,
          ),
          _modeButton(
            "THERMAL",
            Icons.thermostat_rounded,
          ),
          _modeButton(
            "RADAR",
            Icons.radar_rounded,
          ),
        ],
      ),
    );
  }

  Widget _modeButton(
    String mode,
    IconData icon,
  ) {
    final selected = selectedMode == mode;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: ElevatedButton(
  onPressed: () {
    if (mode == "RADAR") {
      _radarAnimationController
        ..reset()
        ..repeat();
    } else {
      _radarAnimationController.stop();
    }

    setState(() {
      selectedMode = mode;
      _showThermalEffect = mode == "THERMAL";
      _showRadarEffect = mode == "RADAR";
    });
  },
          style: ElevatedButton.styleFrom(
            backgroundColor: selected
                ? const Color(0xFF087F5B)
                : Colors.grey.shade800,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              vertical: 11,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 19,
              ),
              const SizedBox(height: 3),
              Text(
                mode,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _RadarPainter extends CustomPainter {
  final double detectionX;
  final double detectionY;
  final double sweepAngle;
  final Animation<double> animation;
  final int confidence;
  final List<Map<String, dynamic>> detections;

  _RadarPainter({
  required this.detectionX,
  required this.detectionY,
  required this.sweepAngle,
  required this.animation,
  required this.confidence,
required this.detections,
}) : super(repaint: animation);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final maxRadius = size.width * 0.42;

    final circlePaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Radar circles
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(
        center,
        maxRadius * i / 4,
        circlePaint,
      );
    }

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      circlePaint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      circlePaint,
    );
    // Radar sweep
final sweepPaint = Paint()
  ..color = Colors.greenAccent.withValues(alpha: 0.75)
  ..style = PaintingStyle.stroke
  ..strokeWidth = 3;

canvas.drawLine(
  center,
  Offset(
    center.dx + maxRadius * math.cos(sweepAngle),
    center.dy + maxRadius * math.sin(sweepAngle),
  ),
  sweepPaint,
);

    // Radar detection point
final pointPaint = Paint()
  ..color = Colors.redAccent
  ..style = PaintingStyle.fill;

for (final detection in detections) {
  final x1 =
      (detection["x1"] as num?)?.toDouble() ?? 0.30;
  final y1 =
      (detection["y1"] as num?)?.toDouble() ?? 0.20;
  final x2 =
      (detection["x2"] as num?)?.toDouble() ?? 0.70;
  final y2 =
      (detection["y2"] as num?)?.toDouble() ?? 0.80;

  final confidence =
      (detection["confidence"] as num?)?.toInt() ?? 0;

  final targetX = ((x1 + x2) / 2) * size.width;
  final targetY = ((y1 + y2) / 2) * size.height;

  final detectionPoint = Offset(
    targetX,
    targetY,
  );

  // Glow
  final glowPaint = Paint()
    ..color = Colors.red.withValues(alpha: 0.25)
    ..style = PaintingStyle.fill;

  canvas.drawCircle(
    detectionPoint,
    22,
    glowPaint,
  );

  // Target point
  final pointPaint = Paint()
    ..color = Colors.redAccent
    ..style = PaintingStyle.fill;

  canvas.drawCircle(
    detectionPoint,
    9,
    pointPaint,
  );

  // Crosshair
  final crosshairPaint = Paint()
    ..color = Colors.redAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  canvas.drawLine(
    Offset(detectionPoint.dx - 18, detectionPoint.dy),
    Offset(detectionPoint.dx + 18, detectionPoint.dy),
    crosshairPaint,
  );

  canvas.drawLine(
    Offset(detectionPoint.dx, detectionPoint.dy - 18),
    Offset(detectionPoint.dx, detectionPoint.dy + 18),
    crosshairPaint,
  );

  // Target label
  final textPainter = TextPainter(
    text: TextSpan(
      text: "POSSIBLE SURVIVOR\n"
          "$confidence% • 4.2 m",
      style: const TextStyle(
        color: Colors.redAccent,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );

  textPainter.layout();

  textPainter.paint(
    canvas,
    Offset(
      detectionPoint.dx - textPainter.width / 2,
      detectionPoint.dy - 42,
    ),
  );
}
    // Center point
    final centerPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      5,
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return true;
  }
}