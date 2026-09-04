import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/satellite_service.dart';
import '../../services/ai_service.dart';

class SatelliteVerificationScreen
    extends StatefulWidget {
  final String reportId;
  final double latitude;
  final double longitude;
  final DateTime? incidentDate;
  final String disasterType;
  final Map<String, dynamic> report;

  const SatelliteVerificationScreen({
  super.key,
  required this.reportId,
  required this.latitude,
  required this.longitude,
  this.incidentDate,
  required this.disasterType,
required this.report,
});

  @override
  State<SatelliteVerificationScreen> createState() =>
      _SatelliteVerificationScreenState();
}

class _SatelliteVerificationScreenState
    extends State<SatelliteVerificationScreen> {
  final SatelliteService _satelliteService =
      SatelliteService();

  bool _loading = true;

  String? _recentImageUrl;
  String? _previousImageUrl;

  String _recentDate = 'Loading...';
  String _previousDate = 'Loading...';

  double? _recentCloudCover;
double? _previousCloudCover;
int? _gapDays;

String _assessment = 'Assessing...';
String _assessmentDetail = '';
Map<String, dynamic>? _satelliteEvidence;
Map<String, dynamic>? _satelliteAIAnalysis;
bool _analyzingSatellite = false;
Map<String, dynamic>? _finalAIAnalysis;
bool _analyzingFinal = false;
String _finalAnalysisStatus = '';

  @override
  void initState() {
    super.initState();
    _loadSatelliteEvidence();
  }

  Future<void> _loadSatelliteEvidence() async {
    try {
      final savedReport =
    await FirebaseFirestore.instance
        .collection("reports")
        .doc(widget.reportId)
        .get();

final savedData = savedReport.data();

final savedSatellite =
    savedData?["satelliteVerification"];

if (savedSatellite is Map<String, dynamic>) {
  final savedSatelliteAI =
      savedSatellite["satelliteAIAnalysis"];

  final savedFinalAI =
      savedSatellite["finalAegisAnalysis"];

  if (savedSatelliteAI is Map<String, dynamic> &&
      savedFinalAI is Map<String, dynamic>) {
    if (!mounted) return;

    setState(() {
      _recentImageUrl =
          savedSatellite["recentImageUrl"]?.toString();

      _previousImageUrl =
          savedSatellite["previousImageUrl"]?.toString();

      _recentDate =
          savedSatellite["recentDate"]?.toString() ??
              "Not available";

      _previousDate =
          savedSatellite["previousDate"]?.toString() ??
              "Not available";

      _recentCloudCover =
          (savedSatellite["recentCloudCover"] as num?)
              ?.toDouble();

      _previousCloudCover =
          (savedSatellite["previousCloudCover"] as num?)
              ?.toDouble();

              _gapDays =
    (savedSatellite["gapDays"] as num?)?.toInt();

      _satelliteAIAnalysis =
          Map<String, dynamic>.from(savedSatelliteAI);

      _finalAIAnalysis =
          Map<String, dynamic>.from(savedFinalAI);

          _buildAssessment();

      _loading = false;
      _analyzingSatellite = false;
      _analyzingFinal = false;
    });

    return;
  }
}
      final result =
          await _satelliteService.getVerificationImagery(
        latitude: widget.latitude,
        longitude: widget.longitude,
        incidentDate:
    widget.incidentDate ?? DateTime.now(),
        radiusKm: 5,
      );

      if (!mounted) return;

      setState(() {
  _recentImageUrl =
      result['recentImageUrl'] as String?;

  _previousImageUrl =
      result['previousImageUrl'] as String?;

  _recentDate =
      result['recentDate']?.toString() ??
          'Not available';

  _previousDate =
      result['previousDate']?.toString() ??
          'Not available';

  _recentCloudCover =
      (result['recentCloudCover'] as num?)
          ?.toDouble();

  _previousCloudCover =
      (result['previousCloudCover'] as num?)
          ?.toDouble();

  _gapDays =
    (result['gapDays'] as num?)?.toInt();

  _buildAssessment();

  _satelliteEvidence = {
  'recentImageAvailable':
      result['recentImageUrl'] != null &&
      result['recentImageUrl']
          .toString()
          .isNotEmpty,

  'previousImageAvailable':
      result['previousImageUrl'] != null &&
      result['previousImageUrl']
          .toString()
          .isNotEmpty,

  'recentDate':
      result['recentDate'] ?? 'Not available',

  'previousDate':
      result['previousDate'] ?? 'Not available',

  'recentCloudCover':
      result['recentCloudCover'] ?? 'Unknown',

  'previousCloudCover':
      result['previousCloudCover'] ?? 'Unknown',

  'assessment': _assessment,

  'details': _assessmentDetail,
};

  _loading = false;
});
if (_recentImageUrl != null &&
    _recentImageUrl!.isNotEmpty &&
    _previousImageUrl != null &&
    _previousImageUrl!.isNotEmpty) {
  await _analyzeSatelliteImages();

  if (_satelliteAIAnalysis != null) {
    await _runFinalAegisAnalysis();
  }
}
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Satellite verification failed: $e',
          ),
        ),
      );
    }
  }

  void _buildAssessment() {
  if (_recentImageUrl == null ||
      _recentImageUrl!.isEmpty) {
    _assessment = 'NEEDS REVIEW';
    _assessmentDetail =
        'No suitable recent satellite imagery '
        'was available for this incident.';
    return;
  }

  if (_recentCloudCover != null &&
      _recentCloudCover! > 60) {
    _assessment = 'NEEDS REVIEW';
    _assessmentDetail =
        'Recent imagery has high cloud cover, '
        'so reliable visual verification may not '
        'be possible.';
    return;
  }

  if (_previousImageUrl == null ||
      _previousImageUrl!.isEmpty) {
    _assessment = 'LIMITED EVIDENCE';
    _assessmentDetail =
        'Recent imagery is available, but a '
        'suitable previous image was not found '
        'for before/after comparison.';
    return;
  }

  _assessment = 'SATELLITE EVIDENCE AVAILABLE';
  _assessmentDetail =
      'Recent and previous satellite imagery '
      'are available for officer comparison. '
      'No automatic disaster confirmation is '
      'made from imagery alone.';
}

Future<void> _analyzeSatelliteImages() async {
  if (_recentImageUrl == null ||
      _recentImageUrl!.isEmpty ||
      _previousImageUrl == null ||
      _previousImageUrl!.isEmpty) {
    return;
  }

  setState(() {
    _analyzingSatellite = true;
  });

  try {
    final analysis =
        await AIService().analyzeSatelliteEvidence(
      disasterType: widget.disasterType,
      recentImageUrl: _recentImageUrl!,
      previousImageUrl: _previousImageUrl!,
    );

    if (!mounted) return;

    setState(() {
      _satelliteAIAnalysis = analysis;
      _analyzingSatellite = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _analyzingSatellite = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Satellite AI analysis failed: $e',
        ),
      ),
    );
  }
}

Future<void> _runFinalAegisAnalysis() async {
  if (_satelliteAIAnalysis == null) {
    return;
  }

  if (!mounted) return;

  setState(() {
    _analyzingFinal = true;
    _finalAnalysisStatus =
        'Collecting weather evidence...';
  });

  try {
    final aiService = AIService();

    final weather =
        await aiService.getWeatherEvidence(
      latitude: widget.latitude,
      longitude: widget.longitude,
    ).timeout(
      const Duration(seconds: 30),
    );

    if (!mounted) return;

    setState(() {
      _finalAnalysisStatus =
          'Checking nearby disaster reports...';
    });

    final nearbyReportCount =
        await aiService.getNearbyReportCount(
      latitude: widget.latitude,
      longitude: widget.longitude,
      radiusKm: 5,
    ).timeout(
      const Duration(seconds: 30),
    );

    if (!mounted) return;

    setState(() {
      _finalAnalysisStatus =
          'Combining satellite, weather and citizen evidence...';
    });

    final imageEvidence =
        widget.report["evidenceStatus"] != null
            ? {
                "evidenceScore":
                    widget.report["evidenceScore"] ?? 0,
                "evidenceStatus":
                    widget.report["evidenceStatus"] ??
                        "UNAVAILABLE",
                "imageRelevant":
                    widget.report["imageRelevant"] ??
                        false,
                "reason":
                    widget.report["evidenceReason"] ??
                        "No image assessment available.",
              }
            : null;

    final satelliteEvidence = {
      "recentImageAvailable":
          _recentImageUrl != null &&
          _recentImageUrl!.isNotEmpty,

      "previousImageAvailable":
          _previousImageUrl != null &&
          _previousImageUrl!.isNotEmpty,

      "recentDate": _recentDate,
      "previousDate": _previousDate,

      "recentCloudCover":
          _recentCloudCover ?? "Unknown",

      "previousCloudCover":
          _previousCloudCover ?? "Unknown",

      "assessment":
          _satelliteAIAnalysis!["status"] ??
              "UNAVAILABLE",

      "details":
          _satelliteAIAnalysis!["details"] ??
              "No satellite analysis available.",

      "changeDetected":
          _satelliteAIAnalysis!["changeDetected"] ??
              false,

      "confidence":
          _satelliteAIAnalysis!["confidence"] ?? 0,

      "limitations":
          _satelliteAIAnalysis!["limitations"] ??
              "No limitations provided.",
    };

    setState(() {
      _finalAnalysisStatus =
          'Running final AEGIS AI assessment...';
    });

    

    final result =
        await aiService.analyzeReportAuthenticity(
      title:
          widget.report["title"]?.toString() ?? "",

      description:
          widget.report["description"]?.toString() ?? "",

      disasterType:
          widget.report["disasterType"]
                  ?.toString() ??
              widget.disasterType,

      severity:
          widget.report["severity"]?.toString() ?? "",

      location:
          widget.report["location"]?.toString() ?? "",

      latitude: widget.latitude,
      longitude: widget.longitude,

      weather: weather,

      nearbyReportCount:
          nearbyReportCount,

      imageEvidence:
          imageEvidence,

      satelliteEvidence:
          satelliteEvidence,
    ).timeout(
      const Duration(seconds: 60),
    );

    if (!mounted) return;

    setState(() {
      _finalAIAnalysis = result;
      _analyzingFinal = false;
      _finalAnalysisStatus = '';
    });

    await FirebaseFirestore.instance
        .collection("reports")
        .doc(widget.reportId)
        .update({
      "satelliteVerification": {
        "recentImageUrl": _recentImageUrl,
        "previousImageUrl": _previousImageUrl,
        "recentDate": _recentDate,
        "previousDate": _previousDate,
        "recentCloudCover": _recentCloudCover,
        "previousCloudCover": _previousCloudCover,
        "gapDays": _gapDays,
        "satelliteAIAnalysis":
            _satelliteAIAnalysis,
        "finalAegisAnalysis": result,
        "analyzedAt": Timestamp.now(),
      },
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _analyzingFinal = false;
      _finalAnalysisStatus = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'AEGIS final analysis failed:\n$e',
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Satellite Verification',
        ),
        backgroundColor:
            const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Satellite Evidence',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
  'Incident location: '
  '${widget.latitude.toStringAsFixed(5)}, '
  '${widget.longitude.toStringAsFixed(5)}',
),

const SizedBox(height: 8),

Text(
  'Disaster Type: ${widget.disasterType}',
  style: const TextStyle(
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 6),

Text(
  'Severity: '
  '${widget.report["severity"]?.toString() ?? "Unknown"}',
  style: const TextStyle(
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 6),

Text(
  'Incident Date: ${_formatIncidentDate(widget.incidentDate)}',
),

const SizedBox(height: 20),

                const Text(
  'BEFORE / AFTER COMPARISON',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 12),

Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: _comparisonImage(
        title: 'PREVIOUS',
        date: _previousDate,
        imageUrl: _previousImageUrl,
      ),
    ),

    const SizedBox(width: 12),

    Expanded(
      child: _comparisonImage(
        title: 'RECENT',
        date: _recentDate,
        imageUrl: _recentImageUrl,
      ),
    ),
  ],
),

const SizedBox(height: 16),

Text(
  'Image gap: '
  '${_gapDays != null ? "$_gapDays day${_gapDays == 1 ? "" : "s"}" : "Unavailable"}',
  style: const TextStyle(
    fontWeight: FontWeight.bold,
  ),
),

                const SizedBox(height: 24),

                Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Satellite Evidence Assessment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          _assessment,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        Text(_assessmentDetail),

        const SizedBox(height: 15),

        Text(
          'Recent cloud cover: '
          '${_recentCloudCover != null ? "${_recentCloudCover!.toStringAsFixed(1)}%" : "Unknown"}',
        ),

        const SizedBox(height: 6),

        Text(
          'Previous cloud cover: '
          '${_previousCloudCover != null ? "${_previousCloudCover!.toStringAsFixed(1)}%" : "Unknown"}',
        ),

        const SizedBox(height: 8),

Text(
  'Image gap: '
  '${_gapDays != null ? "$_gapDays day${_gapDays == 1 ? "" : "s"}" : "Unavailable"}',
  style: const TextStyle(
    fontWeight: FontWeight.bold,
  ),
),

        const SizedBox(height: 12),

        const Text(
          'This satellite evidence assists officer '
          'review and does not independently confirm '
          'or reject a disaster report.',
          style: TextStyle(
            fontSize: 13,
          ),
        ),
      ],
    ),
  ),
),

if (_satelliteAIAnalysis != null &&
    !_analyzingSatellite &&
    !_analyzingFinal) ...[
  SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton.icon(
      icon: const Icon(Icons.refresh),
      label: const Text(
        'Re-analyze Satellite Evidence',
      ),
      onPressed: () async {
        setState(() {
          _satelliteAIAnalysis = null;
          _finalAIAnalysis = null;
          _analyzingSatellite = true;
        });

        await _analyzeSatelliteImages();

        if (!mounted) return;

        if (_satelliteAIAnalysis != null) {
          await _runFinalAegisAnalysis();
        }
      },
    ),
  ),

  const SizedBox(height: 20),
],
const SizedBox(height: 20),

Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: _analyzingSatellite
        ? const Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Satellite AI Analysis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 16),

              Center(
                child: CircularProgressIndicator(),
              ),

              SizedBox(height: 12),

              Center(
                child: Text(
                  'Gemini is comparing satellite images...',
                ),
              ),
            ],
          )
        : _satelliteAIAnalysis == null
            ? const Text(
                'Satellite AI analysis unavailable.',
              )
            : Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Satellite AI Analysis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    'Status: '
                    '${_satelliteAIAnalysis!["status"] ?? "UNAVAILABLE"}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Confidence: '
                    '${_satelliteAIAnalysis!["confidence"] ?? 0}%',
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Change detected: '
                    '${_satelliteAIAnalysis!["changeDetected"] == true ? "YES" : "NO"}',
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _satelliteAIAnalysis!["details"]
                            ?.toString() ??
                        'No details available.',
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Limitations: '
                    '${_satelliteAIAnalysis!["limitations"]?.toString() ?? "No limitations provided."}',
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
  ),
),

const SizedBox(height: 20),

Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: _analyzingFinal
    ? Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'AEGIS Final Assessment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15),
              Center(
                child: CircularProgressIndicator(),
              ),
              Center(
  child: Text(
    _finalAnalysisStatus.isEmpty
        ? 'AEGIS is combining all evidence...'
        : _finalAnalysisStatus,
    textAlign: TextAlign.center,
  ),
),
            ],
          )
        : _finalAIAnalysis == null
            ? const Text(
                'Final AEGIS assessment unavailable.',
              )
            : Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AEGIS Final Assessment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    'Assessment: '
                    '${_finalAIAnalysis!["overallAssessment"] ?? "NEEDS_REVIEW"}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Confidence: '
                    '${_finalAIAnalysis!["overallConfidence"] ?? 0}%',
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Recommendation: '
                    '${_finalAIAnalysis!["officerRecommendation"] ?? "REVIEW"}',
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _finalAIAnalysis!["summary"]
                            ?.toString() ??
                        'No summary available.',
                  ),

                  const SizedBox(height: 18),

const Text(
  'Evidence Breakdown',
  style: TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 10),

_buildEvidenceRow(
  'Location',
  _finalAIAnalysis!["locationAnalysis"],
),

_buildEvidenceRow(
  'Weather',
  _finalAIAnalysis!["weatherAnalysis"],
),

_buildEvidenceRow(
  'Citizen Image',
  _finalAIAnalysis!["imageAnalysis"],
),

_buildEvidenceRow(
  'Satellite',
  _finalAIAnalysis!["satelliteAnalysis"],
),

_buildEvidenceRow(
  'Nearby Reports',
  _finalAIAnalysis!["nearbyReportsAnalysis"],
),
                ],
              ),
  ),
),
              ],
            ),
    );
  }
  String _formatIncidentDate(DateTime? date) {
  if (date == null) {
    return 'Unknown';
  }

  return '${date.day.toString().padLeft(2, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.year}';
}
  Widget _buildEvidenceRow(
  String title,
  dynamic evidence,
) {
  if (evidence is! Map) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        '$title: Unavailable',
      ),
    );
  }

  final status =
      evidence["status"]?.toString() ??
          "UNAVAILABLE";

  final confidence =
      evidence["confidence"] ?? 0;

  final details =
      evidence["details"]?.toString() ??
          "No details available.";

  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          '$title: $status',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'Confidence: $confidence%',
        ),

        const SizedBox(height: 4),

        Text(details),
      ],
    ),
  );
}

  Widget _imageSection({
    required String title,
    required String date,
    required String? imageUrl,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        Text('Date: $date'),

        const SizedBox(height: 10),

        if (imageUrl == null ||
            imageUrl.isEmpty)
          Container(
            height: 220,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Text(
              'No suitable satellite image available',
            ),
          )
        else
          ClipRRect(
            borderRadius:
                BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) {
                return Container(
                  height: 220,
                  alignment: Alignment.center,
                  color: Colors.grey.shade200,
                  child: const Text(
                    'Unable to load satellite image',
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
  Widget _comparisonImage({
  required String title,
  required String date,
  required String? imageUrl,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 4),

      Text(
        date,
        style: const TextStyle(
          fontSize: 12,
        ),
      ),

      const SizedBox(height: 8),

      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: imageUrl == null || imageUrl.isEmpty
            ? Container(
                height: 150,
                alignment: Alignment.center,
                color: Colors.grey.shade200,
                child: const Text(
                  'No image',
                ),
              )
            : Image.network(
                imageUrl,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    alignment: Alignment.center,
                    color: Colors.grey.shade200,
                    child: const Text(
                      'Unable to load',
                    ),
                  );
                },
              ),
      ),
    ],
  );
}
}