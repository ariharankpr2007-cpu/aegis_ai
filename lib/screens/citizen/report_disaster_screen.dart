import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportDisasterScreen extends StatefulWidget {
  const ReportDisasterScreen({super.key});

  @override
  State<ReportDisasterScreen> createState() =>
      _ReportDisasterScreenState();
}

class _ReportDisasterScreenState
    extends State<ReportDisasterScreen> {
      final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  

  String _disasterType = 'Flood';
  String _severity = 'Medium';

  File? _selectedImage;
  Size? _imageSize;
  bool _isScanning = false;
  bool _isGettingLocation = true;
  bool _isSubmitting = false;
  
  String _locationText = 'Getting your current location...';
  String _accuracyText = '';
  double? _incidentLatitude;
double? _incidentLongitude;
 String? _incidentState;
String? _incidentDistrict;
String? _incidentArea;
  List<DetectedObject> _detectedObjects = [];
  YOLO? _yolo;
  bool _isModelLoading = false;

  List<YOLOResult> _yoloBoxes = [];
int _peopleCount = 0;
  static const _types = <String>[
    'Flood',
    'Fire',
    'Earthquake',
    'Cyclone',
    'Landslide',
    'Major Road Accident',
    'Building Collapse',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
  Future<void> _loadImageSize() async {
  if (_selectedImage == null) return;

  final bytes = await _selectedImage!.readAsBytes();

  final codec = await instantiateImageCodec(bytes);

  final frame = await codec.getNextFrame();

  if (!mounted) return;

  setState(() {
    _imageSize = Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
  });
}

  // ================= LOCATION =================
  Future<void> _pickImage(ImageSource source) async {
  final XFile? image = await _imagePicker.pickImage(
    source: source,
    imageQuality: 85,
  );

  if (image == null) return;

  setState(() {
    _selectedImage = File(image.path);
    _yoloBoxes.clear();
    _peopleCount = 0;
    _imageSize = null;
  });

  await _loadImageSize();
}
  Future<void> _getCurrentLocation() async {
  setState(() {
    _isGettingLocation = true;
  });

  try {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception("Location services are disabled");
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception("Location permission denied");
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        "Location permission permanently denied",
      );
    }

    final position =
        await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final placemarks =
        await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    String address = "Unknown location";

    String? incidentState;
    String? incidentDistrict;
    String? incidentArea;

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;

      incidentState =
          place.administrativeArea?.trim();

      incidentDistrict =
          place.subAdministrativeArea?.trim();

      incidentArea =
          place.subLocality?.trim().isNotEmpty == true
              ? place.subLocality!.trim()
              : place.locality?.trim();

      final addressParts = [
        place.name,
        place.street,
        place.subLocality,
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
        place.postalCode,
      ]
          .where(
            (part) =>
                part != null &&
                part.toString().trim().isNotEmpty,
          )
          .map((part) => part.toString().trim())
          .toList();

      address = addressParts.join(", ");
    }

    if (!mounted) return;

    setState(() {
      _incidentLatitude = position.latitude;
      _incidentLongitude = position.longitude;

      _incidentState = incidentState;
      _incidentDistrict = incidentDistrict;
      _incidentArea = incidentArea;

      _locationText = address;

      _accuracyText =
          'Location accuracy: ±${position.accuracy.toStringAsFixed(0)} m';

      _isGettingLocation = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _isGettingLocation = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Unable to get location: $e",
        ),
      ),
    );
  }
}
Future<void> _loadYoloModel() async {
  if (_yolo != null) return;

  setState(() => _isModelLoading = true);

  try {
    _yolo = YOLO(
      modelPath: 'yolo26n',
    );

    await _yolo!.loadModel();
  } catch (e) {
    _yolo = null;
    rethrow;
  } finally {
    if (mounted) {
      setState(() => _isModelLoading = false);
    }
  }
}

Future<void> _scanWithAi() async {
  if (_selectedImage == null) {
    _showMessage('Choose a photo before starting AI Scan.');
    return;
  }

  setState(() {
    _isScanning = true;
    _peopleCount = 0;
    _yoloBoxes = [];
  });

  try {
    await _loadYoloModel();

    final imageBytes = await _selectedImage!.readAsBytes();
    final results = await _yolo!.predict(imageBytes);

    final rawBoxes = List<dynamic>.from(
      results['boxes'] ?? [],
    );

    final personBoxes = rawBoxes
        .map(
          (box) => YOLOResult.fromMap(
            Map<String, dynamic>.from(box),
          ),
        )
        .where(
          (result) =>
              result.className.toLowerCase() == 'person',
        )
        .toList();

    if (!mounted) return;

    debugPrint('YOLO PEOPLE COUNT: ${personBoxes.length}');

for (final person in personBoxes) {
  debugPrint(
    'BOX: ${person.normalizedBox}',
  );
}

setState(() {
  _yoloBoxes = List<YOLOResult>.from(personBoxes);
  _peopleCount = personBoxes.length;
  _isScanning = false;
});

    _showMessage(
      'AI complete: $_peopleCount people detected.',
    );
  } catch (e) {
    if (!mounted) return;

    setState(() => _isScanning = false);

    _showMessage(
      'AI scan failed: $e',
    );
  }
}

Future<Map<String, dynamic>?>
    _findNearestAvailableRescueTeam() async {

  if (_incidentLatitude == null ||
      _incidentLongitude == null) {
    return null;
  }

  // Get only teams that are operational
  final snapshot = await FirebaseFirestore.instance
      .collection('rescueTeams')
      .where('status', isEqualTo: 'Available')
      .where('isActive', isEqualTo: true)
      .where('isApproved', isEqualTo: true)
      .get();

  final List<Map<String, dynamic>> districtTeams = [];

  for (final doc in snapshot.docs) {
    final data = doc.data();

    final teamDistrict =
        data['district']?.toString().trim();

    // Only consider teams in the same district
    if (_incidentDistrict != null &&
    _incidentDistrict!.isNotEmpty) {
  if (teamDistrict == null ||
      teamDistrict.isEmpty ||
      teamDistrict.toLowerCase() !=
          _incidentDistrict!.toLowerCase()) {
    continue;
  }
}

    final latitude = data['latitude'];
    final longitude = data['longitude'];

    if (latitude == null || longitude == null) {
      continue;
    }

    final teamLatitude =
        (latitude as num).toDouble();

    final teamLongitude =
        (longitude as num).toDouble();

    final distance =
        Geolocator.distanceBetween(
      _incidentLatitude!,
      _incidentLongitude!,
      teamLatitude,
      teamLongitude,
    );

    districtTeams.add({
      'id': doc.id,
      'name': data['name'] ?? 'Rescue Team',
      'distance': distance,
      'specialization':
          data['specialization'] ?? '',
      'state': data['state'] ?? '',
      'district': data['district'] ?? '',
      'area': data['area'] ?? '',
      'officerId': data['officerId'],
    });
  }

  if (districtTeams.isEmpty) {
    return null;
  }

  // ==================================================
  // PRIORITY 1: SAME LOCAL AREA
  // ==================================================

  final sameAreaTeams =
      districtTeams.where((team) {

    final teamArea =
        team['area'].toString().trim();

    if (_incidentArea == null ||
        _incidentArea!.isEmpty ||
        teamArea.isEmpty) {
      return false;
    }

    return teamArea.toLowerCase() ==
        _incidentArea!.toLowerCase();
  }).toList();

  List<Map<String, dynamic>> teamsToCheck;

  if (sameAreaTeams.isNotEmpty) {

    // Local rescue team exists and is available
    teamsToCheck = sameAreaTeams;

  } else {

    // Local team unavailable → search district
    teamsToCheck = districtTeams;
  }

  // ==================================================
  // FIND NEAREST TEAM
  // ==================================================

  Map<String, dynamic>? nearestTeam;
  double shortestDistance = double.infinity;

  for (final team in teamsToCheck) {

    final distance =
        team['distance'] as double;

    if (distance < shortestDistance) {
      shortestDistance = distance;
      nearestTeam = team;
    }
  }

  return nearestTeam;
}

Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  if (_incidentLatitude == null ||
      _incidentLongitude == null) {
    _showMessage(
      'Please wait for accurate location before submitting.',
    );
    return;
  }

  setState(() => _isSubmitting = true);

  try {
    // 1. Find nearest ACTIVE + AVAILABLE rescue team
    final assignedTeam =
        await _findNearestAvailableRescueTeam();

    // 2. Create report reference
    final reportRef =
        FirebaseFirestore.instance
            .collection('reports')
            .doc();

    // 3. Save disaster report
    await reportRef.set({
      'title': _disasterType,
      'disasterType': _disasterType,

      'severity': _severity,

      'description':
          _descriptionController.text.trim(),

      'location': _locationText,

// Geographic hierarchy
'state': _incidentState,
'district': _incidentDistrict,
'area': _incidentArea,

'latitude': _incidentLatitude,
'longitude': _incidentLongitude,

      // AI RESULT
      'aiAnalyzed': _yoloBoxes.isNotEmpty,
      'peopleCount': _peopleCount,

      // Save bounding box data
      'aiDetections': _yoloBoxes.map((box) {
        final rect = box.normalizedBox;

        return {
          'className': box.className,
          'confidence': box.confidence,
          'left': rect.left,
          'top': rect.top,
          'right': rect.right,
          'bottom': rect.bottom,
        };
      }).toList(),

      // AUTO ASSIGNMENT
      'assignedTo':
          assignedTeam?['id'],

      'assignedName':
          assignedTeam?['name'],

      'assignedDistanceMeters':
          assignedTeam?['distance'],

      'assignedSpecialization':
          assignedTeam?['specialization'],
          // District officer responsible for this area
'officerId':
    assignedTeam?['officerId'],

      // IMPORTANT
      'status':
          assignedTeam != null
              ? 'Assigned'
              : 'Pending Assignment',

      'createdAt':
          FieldValue.serverTimestamp(),
    });

    // 4. Notify assigned rescue team
    if (assignedTeam != null) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'receiverId': assignedTeam['id'],

        'title':
            '🚨 New Emergency Assigned',

        'body':
            '$_disasterType emergency. '
            '$_peopleCount people detected by AI.',

        'type':
            'assignment',

        'reportId':
            reportRef.id,

        'isRead': false,

        'timestamp':
            Timestamp.now(),
      });

      // Make the team unavailable/busy
      await FirebaseFirestore.instance
          .collection('rescueTeams')
          .doc(assignedTeam['id'])
          .update({
        'status': 'Busy',
        'currentReportId': reportRef.id,
      });
    }

    if (!mounted) return;

    if (assignedTeam != null) {
      final distance =
          (assignedTeam['distance'] as double);

      _showMessage(
        'AI assigned the nearest rescue team '
        '(${(distance / 1000).toStringAsFixed(1)} km away).',
      );
    } else {
      _showMessage(
        'Report submitted. No active rescue team is currently available.',
      );
    }

    await Future<void>.delayed(
      const Duration(seconds: 1),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  } catch (e) {
    _showMessage(
      'Failed to submit report: $e',
    );
  } finally {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        title: const Text(
          'Report Disaster',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: ListView(
            padding: const EdgeInsets.all(16),

            children: [

              // HEADER

              Container(
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.orange.shade200,
                  ),
                ),

                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 35,
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report a Disaster',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            'Share accurate information to help emergency responders.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // LOCATION CARD

              const Text(
                'CURRENT LOCATION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 8),

              Card(
                elevation: 1,

                child: Padding(
                  padding:
                      const EdgeInsets.all(16),

                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 30,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            if (_isGettingLocation)
                              const Row(
                                children: [
                                  SizedBox(
                                    height: 18,
                                    width: 18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),

                                  SizedBox(width: 10),

                                  Text(
                                    'Getting location...',
                                  ),
                                ],
                              )
                            else
                              Text(
                                _locationText,
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),

                            if (_accuracyText.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(
                                  top: 5,
                                ),
                                child: Text(
                                  _accuracyText,
                                  style: TextStyle(
                                    color:
                                        Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed:
                            _isGettingLocation
                                ? null
                                : _getCurrentLocation,

                        icon: const Icon(
                          Icons.refresh,
                        ),

                        tooltip:
                            'Refresh location',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // DISASTER TYPE

              const Text(
                'DISASTER TYPE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: _disasterType,

                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),

                  prefixIcon: const Icon(
                    Icons.warning_amber_rounded,
                  ),
                ),

                items: _types
                    .map(
                      (type) =>
                          DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(),

                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _disasterType = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              // SEVERITY

              const Text(
                'SEVERITY',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,

                children: [
                  'Low',
                  'Medium',
                  'High',
                  'Critical',
                ].map((level) {
                  return ChoiceChip(
                    label: Text(level),

                    selected:
                        _severity == level,

                    onSelected: (_) {
                      setState(() {
                        _severity = level;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // DESCRIPTION

              const Text(
                'WHAT HAPPENED?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller:
                    _descriptionController,

                minLines: 5,
                maxLines: 7,

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please describe the situation.';
                  }

                  return null;
                },

                decoration: InputDecoration(
                  hintText:
                      'Describe the situation, possible danger and people affected...',

                  filled: true,
                  fillColor: Colors.white,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // PHOTO

              const Text(
                'PHOTO EVIDENCE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),

              SizedBox(
  height: 220,
  width: double.infinity,
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: _selectedImage == null
        ? Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Text(
              'Add photo evidence if safe',
            ),
          )
        : Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                _selectedImage!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),

              if (_yoloBoxes.isNotEmpty)
                IgnorePointer(
                  child: CustomPaint(
  painter: YoloBoxPainter(
    boxes: _yoloBoxes,
    imageSize: _imageSize,
  ),
),
                ),
            ],
          ),
  ),
),


              const SizedBox(height: 12),

              Row(
                children: [

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _pickImage(
                        ImageSource.camera,
                      ),

                      icon: const Icon(
                        Icons.camera_alt_outlined,
                      ),

                      label:
                          const Text('Camera'),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _pickImage(
                        ImageSource.gallery,
                      ),

                      icon: const Icon(
                        Icons.photo_library_outlined,
                      ),

                      label:
                          const Text('Gallery'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // AI

              OutlinedButton.icon(
                onPressed:
                    _isScanning
                        ? null
                        : _scanWithAi,

                icon: _isScanning
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.psychology_outlined,
                      ),

                label: Text(
                  _isScanning
                      ? 'Analyzing...'
                      : 'Analyze Photo with AI',
                ),
              ),

              const SizedBox(height: 12),

if (_selectedImage != null && !_isScanning)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.green,
      ),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.people,
          color: Colors.green,
        ),
        const SizedBox(width: 10),
        Text(
          'AI detected $_peopleCount people',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),

const SizedBox(height: 24),

// SUBMIT

              FilledButton.icon(
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      Colors.red.shade700,

                  minimumSize:
                      const Size.fromHeight(58),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),

                onPressed:
                    _isSubmitting
                        ? null
                        : _submit,

                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.warning_rounded,
                      ),

                label: Text(
                  _isSubmitting
                      ? 'SUBMITTING...'
                      : 'SUBMIT DISASTER REPORT',

                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}

class YoloBoxPainter extends CustomPainter {
  final List<YOLOResult> boxes;
  final Size? imageSize;

  YoloBoxPainter({
    required this.boxes,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == null) return;

    final boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.red;

    for (int i = 0; i < boxes.length; i++) {
      final box = boxes[i].normalizedBox;

      double left = box.left;
      double top = box.top;
      double right = box.right;
      double bottom = box.bottom;

      // If coordinates are pixel coordinates,
      // convert them to normalized coordinates.
      if (left > 1 ||
          top > 1 ||
          right > 1 ||
          bottom > 1) {
        left = left / imageSize!.width;
        right = right / imageSize!.width;
        top = top / imageSize!.height;
        bottom = bottom / imageSize!.height;
      }

      // Convert normalized coordinates to screen coordinates
      final rect = Rect.fromLTRB(
        left * size.width,
        top * size.height,
        right * size.width,
        bottom * size.height,
      );

      canvas.drawRect(rect, boxPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Person ${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final labelTop =
          rect.top > 28 ? rect.top - 28 : rect.top;

      canvas.drawRect(
        Rect.fromLTWH(
          rect.left,
          labelTop,
          textPainter.width + 12,
          25,
        ),
        Paint()..color = Colors.red,
      );

      textPainter.paint(
        canvas,
        Offset(
          rect.left + 6,
          labelTop + 5,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant YoloBoxPainter oldDelegate,
  ) {
    return true;
  }
}