import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class AIService {
  final GenerativeModel _model =
      FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.5-flash',
  );

  Future<String> testAI() async {
    final response = await _model.generateContent([
      Content.text(
        'You are the AI system of AEGIS, a disaster management application. '
        'Reply with exactly: AEGIS AI connection successful.',
      ),
    ]);

    return response.text ?? 'No response from AI.';
  }
 Future<Map<String, dynamic>> getWeatherEvidence({
  required double latitude,
  required double longitude,
}) async {
  final uri = Uri.parse(
    'https://api.open-meteo.com/v1/forecast'
    '?latitude=$latitude'
    '&longitude=$longitude'
    '&current=temperature_2m,relative_humidity_2m,precipitation,rain,showers,wind_speed_10m,wind_gusts_10m,weather_code'
'&hourly=temperature_2m,relative_humidity_2m,precipitation,rain,showers,wind_speed_10m,wind_gusts_10m,weather_code'
'&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max'
    '&past_days=1'
    '&forecast_days=2'
    '&timezone=auto',
  );

  final response = await http.get(uri);

  if (response.statusCode != 200) {
    throw Exception(
      'Weather service failed: ${response.statusCode}',
    );
  }

  final data =
      jsonDecode(response.body) as Map<String, dynamic>;

  final current =
      data["current"] as Map<String, dynamic>?;

  final daily = data['daily'] as Map<String, dynamic>?;

  final dailyWeatherCodes =
    List<dynamic>.from(daily?['weather_code'] ?? []);

final dailyMaxTemps =
    List<dynamic>.from(daily?['temperature_2m_max'] ?? []);

final dailyMinTemps =
    List<dynamic>.from(daily?['temperature_2m_min'] ?? []);

final dailyRainProbability =
    List<dynamic>.from(
      daily?['precipitation_probability_max'] ?? [],
    );

  final hourly =
      data["hourly"] as Map<String, dynamic>?;

  if (current == null || hourly == null) {
    throw Exception(
      'Weather data is unavailable.',
    );
  }

  final times =
      List<String>.from(hourly["time"] ?? []);

  final precipitation =
      List<num>.from(
        hourly["precipitation"] ?? [],
      );

  final rain =
      List<num>.from(
        hourly["rain"] ?? [],
      );

  final showers =
      List<num>.from(
        hourly["showers"] ?? [],
      );

  final temperature =
      List<num>.from(
        hourly["temperature_2m"] ?? [],
      );

  final humidity =
      List<num>.from(
        hourly["relative_humidity_2m"] ?? [],
      );

  final windSpeed =
      List<num>.from(
        hourly["wind_speed_10m"] ?? [],
      );

      final windGusts =
    List<num>.from(
      hourly["wind_gusts_10m"] ?? [],
    );

  final weatherCodes =
      List<num>.from(
        hourly["weather_code"] ?? [],
      );

  double rainfallLast24Hours = 0;
double rainLast24Hours = 0;
double showersLast24Hours = 0;

double rainfallNext24Hours = 0;
double maxWindNext24Hours = 0;
double maxWindGustNext24Hours = 0;

int thunderstormHoursNext24 = 0;

final now = DateTime.now();

for (int i = 0; i < times.length; i++) {
  final weatherTime = DateTime.tryParse(times[i]);

  if (weatherTime == null) {
    continue;
  }

  final difference = weatherTime.difference(now).inHours;

  // Previous 24 hours
  if (difference <= 0 && difference >= -24) {
    rainfallLast24Hours += precipitation[i].toDouble();
    rainLast24Hours += rain[i].toDouble();
    showersLast24Hours += showers[i].toDouble();
  }

  // Next 24 hours
  if (difference > 0 && difference <= 24) {
    rainfallNext24Hours += precipitation[i].toDouble();

    maxWindNext24Hours =
        max(maxWindNext24Hours, windSpeed[i].toDouble());

    maxWindGustNext24Hours =
        max(maxWindGustNext24Hours, windGusts[i].toDouble());

    final code = weatherCodes[i].toInt();

    // WMO thunderstorm weather codes
    if (code == 95 || code == 96 || code == 99) {
      thunderstormHoursNext24++;
    }
  }
}
  print("=== AEGIS LIVE WEATHER ===");
print("Latitude: $latitude");
print("Longitude: $longitude");
print("Current temperature: ${current["temperature_2m"]}");
print("Current rain: ${current["rain"]}");
print("Current precipitation: ${current["precipitation"]}");
print("Rainfall last 24h: $rainfallLast24Hours");
print("Rain last 24h: $rainLast24Hours");
print("Weather code: ${current["weather_code"]}");
print("==========================");


  return {
    // Current weather
    "temperature":
        current["temperature_2m"],

    "humidity":
        current["relative_humidity_2m"],

    "precipitation":
        current["precipitation"],

    "rain":
        current["rain"],

    "showers":
        current["showers"],

    "windSpeed":
        current["wind_speed_10m"],

    "weatherCode":
        current["weather_code"],

    // Previous 24-hour weather
    "rainfallLast24Hours":
        rainfallLast24Hours,

    "rainLast24Hours":
        rainLast24Hours,

    "showersLast24Hours":
        showersLast24Hours,

  // Next 24-hour forecast safety data
"rainfallNext24Hours":
    rainfallNext24Hours,

"maxWindNext24Hours":
    maxWindNext24Hours,

"maxWindGustNext24Hours":
    maxWindGustNext24Hours,

"thunderstormHoursNext24":
    thunderstormHoursNext24,

    // Location
    "latitude":
        latitude,

    "longitude":
        longitude,

        'todayWeatherCode':
    dailyWeatherCodes.isNotEmpty ? dailyWeatherCodes[0] : null,

'todayMaxTemp':
    dailyMaxTemps.isNotEmpty ? dailyMaxTemps[0] : null,

'todayMinTemp':
    dailyMinTemps.isNotEmpty ? dailyMinTemps[0] : null,

'todayRainProbability':
    dailyRainProbability.isNotEmpty
        ? dailyRainProbability[0]
        : null,

'tomorrowWeatherCode':
    dailyWeatherCodes.length > 1
        ? dailyWeatherCodes[1]
        : null,

'tomorrowMaxTemp':
    dailyMaxTemps.length > 1
        ? dailyMaxTemps[1]
        : null,

'tomorrowMinTemp':
    dailyMinTemps.length > 1
        ? dailyMinTemps[1]
        : null,

'tomorrowRainProbability':
    dailyRainProbability.length > 1
        ? dailyRainProbability[1]
        : null,
  };
}
Future<int> getNearbyReportCount({
  required double latitude,
  required double longitude,
  double radiusKm = 5,
}) async {
  final snapshot = await FirebaseFirestore.instance
      .collection("reports")
      .get();

  int count = 0;

  for (final doc in snapshot.docs) {
    final data =
        doc.data() as Map<String, dynamic>;

    final reportLatitude =
        (data["latitude"] as num?)?.toDouble();

    final reportLongitude =
        (data["longitude"] as num?)?.toDouble();

    if (reportLatitude == null ||
        reportLongitude == null) {
      continue;
    }

    final distanceKm =
        _calculateDistanceKm(
      latitude,
      longitude,
      reportLatitude,
      reportLongitude,
    );

    if (distanceKm <= radiusKm) {
      count++;
    }
  }

  return count;
}
Future<Map<String, dynamic>> analyzeReportAuthenticity({
  required String title,
  required String description,
  required String disasterType,
  required String severity,
  required String location,
  required double latitude,
  required double longitude,
  required Map<String, dynamic> weather,
  required int nearbyReportCount,
  Map<String, dynamic>? imageEvidence,
}) async {
  final prompt = '''
You are AEGIS AI, an emergency disaster-report verification system.

Your job is to analyze multiple independent signals about a citizen's
disaster report.

IMPORTANT:
Do NOT decide that a report is real or fake based only on the citizen's
description.

The description may be empty, short, incomplete, exaggerated, or misleading.

Analyze the following evidence together:

================ REPORT INFORMATION ================

Title:
$title

Disaster Type:
$disasterType

Citizen Selected Severity:
$severity

Description:
${description.isEmpty ? "Not provided" : description}

Reported Location:
$location

GPS Latitude:
$latitude

GPS Longitude:
$longitude

================ WEATHER EVIDENCE ================

Temperature:
${weather["temperature"]}

Humidity:
${weather["humidity"]}

Current Precipitation:
${weather["precipitation"]}

Current Rain:
${weather["rain"]}

Current Showers:
${weather["showers"]}

Wind Speed:
${weather["windSpeed"]}

Weather Code:
${weather["weatherCode"]}

Rainfall During Previous 24 Hours:
${weather["rainfallLast24Hours"]}

Rain During Previous 24 Hours:
${weather["rainLast24Hours"]}

Showers During Previous 24 Hours:
${weather["showersLast24Hours"]}

================ NEARBY REPORTS ================

Number of nearby citizen reports within approximately 5 km:
$nearbyReportCount

================ IMAGE EVIDENCE ================

${imageEvidence == null ? "No image was submitted." : '''
Evidence Score:
${imageEvidence["evidenceScore"]}

Evidence Status:
${imageEvidence["evidenceStatus"]}

Image Relevant:
${imageEvidence["imageRelevant"]}

Evidence Assessment:
${imageEvidence["reason"]}
'''}

=====================================================

Analyze these signals independently and then combine them.

IMPORTANT PRIORITY:

For the final authenticity assessment, environmental and
location-based evidence must carry more importance than the
image or citizen description.

Use this evidence priority:

1. Location-specific weather and environmental conditions
2. Location consistency
3. Corroboration from nearby reports
4. Image evidence
5. Citizen-provided information

You MUST evaluate:

1. Location consistency
2. Current weather consistency
3. Recent weather consistency
4. Disaster-specific environmental consistency
5. Nearby citizen reports
6. Image evidence
7. Citizen-provided information

The image can show that a disaster is visually present, but a
strong image alone must NOT make the overall report
LIKELY_GENUINE.

The citizen's description must NOT make the overall report
LIKELY_GENUINE.

When weather and location evidence do not support the reported
disaster, the final assessment must reflect that uncertainty
even if the image looks convincing.

When weather evidence is neutral or unavailable, do not invent
supporting environmental conditions.

When multiple independent signals support the incident at the
reported location, confidence may increase.

The final assessment must reflect the combined evidence, not
the strongest single signal.

The citizen description must be treated as SUPPORTING INFORMATION only.
It must never be treated as proof.

Weather analysis must be based on the supplied location-specific
weather data.

For disasters such as floods, do not evaluate weather using only
current rainfall.

Consider recent rainfall and recent environmental conditions.

A lack of current rainfall does NOT automatically mean that a flood
is impossible, because flooding can continue after rainfall stops.

Evaluate weather according to the reported disaster type.

Do not claim that weather proves a disaster occurred.
Weather is supporting environmental evidence.

For missing information:
- Do not assume it is false.
- Mark the information as unavailable or limited.
- A missing description should not automatically reduce the report to false.
- A missing image should not automatically mean the report is false.

Return ONLY valid JSON in exactly this structure:

{
  "overallAssessment": "LIKELY_GENUINE",
  "overallConfidence": 87,

  "locationAnalysis": {
    "status": "CONSISTENT",
    "confidence": 92,
    "details": "GPS location is consistent with the reported location."
  },

  "weatherAnalysis": {
    "status": "SUPPORTING",
    "confidence": 88,
    "details": "Current weather conditions provide supporting evidence for the reported disaster."
  },

  "imageAnalysis": {
    "status": "STRONG",
    "confidence": 94,
    "details": "Submitted image contains visible evidence relevant to the reported disaster."
  },

  "nearbyReportsAnalysis": {
    "status": "CORROBORATED",
    "confidence": 91,
    "details": "Multiple nearby reports provide independent corroboration."
  },

  "reportInformationAnalysis": {
  "status": "LIMITED",
  "confidence": 55,
  "details": "The citizen provided limited descriptive information."
},

"summary": "Multiple independent signals support the reported incident.",

"keyEvidence": [
  "Strongest supporting evidence 1",
  "Strongest supporting evidence 2",
  "Strongest supporting evidence 3"
],

"contradictingEvidence": [
  "Important conflicting evidence 1",
  "Important conflicting evidence 2"
],

"officerRecommendation": "VERIFY"
}

Rules:

- overallAssessment must be exactly one of:
  LIKELY_GENUINE
  NEEDS_REVIEW
  LIKELY_SUSPICIOUS

- overallConfidence must be an integer from 0 to 100.

- Each individual confidence must be an integer from 0 to 100.

- location status must be one of:
  CONSISTENT
  INCONSISTENT
  LIMITED

- weather status must be one of:
  SUPPORTING
  NOT_SUPPORTING
  NEUTRAL
  UNAVAILABLE

- image status must be one of:
  STRONG
  MODERATE
  WEAK
  UNAVAILABLE

- nearby reports status must be one of:
  CORROBORATED
  LIMITED
  NO_CORROBORATION

- report information status must be one of:
  DETAILED
  LIMITED
  NOT_PROVIDED

- officerRecommendation must be exactly one of:
  VERIFY
  REVIEW
  INVESTIGATE

- Do not declare the report definitely real.
- Do not declare the report definitely fake.
- Do not invent weather conditions.

- keyEvidence must contain the strongest evidence supporting
  the report.

- contradictingEvidence must contain important evidence that
  weakens or conflicts with the report.

- Do not invent evidence.

- If there is no meaningful supporting evidence, return
  an empty keyEvidence list.

- If there is no meaningful contradicting evidence, return
  an empty contradictingEvidence list.

- overallAssessment must be based on the combined evidence.

- The final assessment must not be determined by the image alone.
- Do not invent nearby reports.
- Do not invent facts about the location.
- Use only the supplied information.
- Do not include Markdown.
- Do not include ```json.
''';

  final response = await _model.generateContent([
    Content.text(prompt),
  ]);

  final text = response.text;

  if (text == null || text.trim().isEmpty) {
    throw Exception(
      'Gemini returned an empty authenticity analysis.',
    );
  }

  String cleaned = text.trim();

  if (cleaned.startsWith('```json')) {
    cleaned = cleaned
        .replaceFirst('```json', '')
        .replaceFirst('```', '')
        .trim();
  } else if (cleaned.startsWith('```')) {
    cleaned = cleaned
        .replaceFirst('```', '')
        .replaceFirst('```', '')
        .trim();
  }

  final decoded = jsonDecode(cleaned);

  if (decoded is! Map<String, dynamic>) {
    throw Exception(
      'Invalid authenticity analysis format.',
    );
  }

  return decoded;
}
double _calculateDistanceKm(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadiusKm = 6371.0;

  final dLat =
      (lat2 - lat1) * pi / 180;

  final dLon =
      (lon2 - lon1) * pi / 180;

  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final c =
      2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadiusKm * c;
}

  // ============================================================
  // DISASTER PRIORITY ANALYSIS
  // ============================================================

  Future<List<Map<String, dynamic>>> analyzeDisasters(
    List<Map<String, dynamic>> reports,
  ) async {
    final reportsText = reports.asMap().entries.map((entry) {
      final index = entry.key;
      final report = entry.value;

      return '''
REPORT_INDEX: $index
Title: ${report["title"] ?? ""}
Disaster Type: ${report["disasterType"] ?? ""}
Location: ${report["location"] ?? ""}
Reported Severity: ${report["severity"] ?? ""}
Description: ${report["description"] ?? ""}
''';
    }).join('\n----------------------\n');

    final prompt = '''
You are the real AI disaster-priority analysis system for AEGIS AI.

Analyze ALL disaster reports below and determine how urgently an officer
should respond to each one.

$reportsText

For every report evaluate:

- danger to human life
- number or vulnerability of people potentially affected
- urgency of rescue
- spread/escalation risk
- infrastructure/property danger
- reported severity
- whether immediate intervention is required

Return ONLY valid JSON.

The response MUST be an array in exactly this format:

[
  {
    "reportIndex": 0,
    "priority": "CRITICAL",
    "score": 95,
    "reason": "Short explanation."
  }
]

Rules:

- Return exactly one result for every REPORT_INDEX.
- reportIndex must match the supplied REPORT_INDEX.
- priority must be exactly one of:
  CRITICAL, HIGH, MEDIUM, LOW
- score must be an integer from 0 to 100.
- CRITICAL = immediate threat to life or very urgent rescue.
- HIGH = serious danger requiring rapid response.
- MEDIUM = significant incident but not immediately life-threatening.
- LOW = limited danger or lower urgency.
- Do not invent victims or facts.
- Base the analysis only on the information provided.
- Do not include Markdown.
- Do not include ```json.
''';

    final response = await _model.generateContent([
      Content.text(prompt),
    ]);

    final text = response.text;

    if (text == null || text.trim().isEmpty) {
      throw Exception('Gemini returned an empty response.');
    }

    String cleaned = text.trim();

    if (cleaned.startsWith('```json')) {
      cleaned = cleaned
          .replaceFirst('```json', '')
          .replaceFirst('```', '')
          .trim();
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst('```', '')
          .replaceFirst('```', '')
          .trim();
    }

    final decoded = jsonDecode(cleaned);

    if (decoded is! List) {
      throw Exception('Invalid AI response format.');
    }

    final results = <Map<String, dynamic>>[];

    for (final item in decoded) {
      if (item is! Map) continue;

      final priority = item["priority"];
      final score = item["score"];
      final reason = item["reason"];
      final reportIndex = item["reportIndex"];

      if (priority == null ||
          score == null ||
          reason == null ||
          reportIndex == null) {
        continue;
      }

      results.add({
        "reportIndex": (reportIndex as num).toInt(),
        "priority": priority.toString().toUpperCase(),
        "score": (score as num).toInt(),
        "reason": reason.toString(),
      });
    }

    if (results.isEmpty) {
      throw Exception(
        'Gemini returned no valid disaster analysis.',
      );
    }

    return results;
  }

  // ============================================================
  // RESCUE TEAM RECOMMENDATION
  // ============================================================

  Future<Map<String, dynamic>> recommendRescueTeam({
    required String disasterType,
    required String severity,
    required String location,
    required String description,
    required List<Map<String, dynamic>> rescueTeams,
  }) async {
    final teamsText =
        rescueTeams.asMap().entries.map((entry) {
      final index = entry.key;
      final team = entry.value;

      return '''
TEAM_INDEX: $index
Team ID: ${team["id"]}
Team Name: ${team["name"]}
Status: ${team["status"]}
Approved: ${team["isApproved"]}
Latitude: ${team["latitude"]}
Longitude: ${team["longitude"]}
Specialization: ${team["specialization"] ?? "Not specified"}
''';
    }).join('\n----------------------\n');

    final prompt = '''
You are the rescue-team recommendation AI for AEGIS AI.

Analyze the disaster and the available rescue teams.

DISASTER:
Type: $disasterType
Severity: $severity
Location: $location
Description: $description

AVAILABLE RESCUE TEAMS:

$teamsText

Choose the most suitable rescue team.

Consider:

- disaster type
- severity
- team specialization
- team availability
- approval status
- approximate location suitability

Return ONLY valid JSON in exactly this format:

{
  "teamIndex": 0,
  "teamId": "TEAM_ID",
  "teamName": "Team Name",
  "reason": "Short explanation of why this team is suitable.",
  "emergencyPlan": {
    "immediateActions": [
      "Immediate action 1",
      "Immediate action 2",
      "Immediate action 3"
    ],
    "safetyPrecautions": [
      "Safety precaution 1",
      "Safety precaution 2"
    ],
    "resourcesRequired": [
      "Required resource 1",
      "Required resource 2"
    ]
  }
}

Rules:

- teamIndex must correspond to one of the supplied teams.
- teamId must exactly match the selected team's ID.
- Do not invent a team.
- Only recommend a team from the supplied list.
- Prefer approved and available teams.
- Do not invent facts that are not provided.
- Emergency actions must be practical and relevant to the reported disaster.
- Do not invent victims, equipment, or conditions.
- Return 3 to 5 immediate actions.
- Return 2 to 4 safety precautions.
- Return 2 to 5 required resources.
- Do not include Markdown.
- Do not include ```json.
''';

    final response = await _model.generateContent([
      Content.text(prompt),
    ]);

    final text = response.text;

    if (text == null || text.trim().isEmpty) {
      throw Exception('Gemini returned an empty response.');
    }

    String cleaned = text.trim();

    if (cleaned.startsWith('```json')) {
      cleaned = cleaned
          .replaceFirst('```json', '')
          .replaceFirst('```', '')
          .trim();
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst('```', '')
          .replaceFirst('```', '')
          .trim();
    }

    final decoded = jsonDecode(cleaned);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid AI recommendation format.');
    }

    if (decoded["teamIndex"] == null ||
        decoded["teamId"] == null ||
        decoded["teamName"] == null ||
        decoded["reason"] == null ||
        decoded["emergencyPlan"] == null) {
      throw Exception(
        'AI recommendation is missing required fields.',
      );
    }

    return {
      "teamIndex": (decoded["teamIndex"] as num).toInt(),
      "teamId": decoded["teamId"].toString(),
      "teamName": decoded["teamName"].toString(),
      "reason": decoded["reason"].toString(),
      "emergencyPlan": decoded["emergencyPlan"],
    };
  }

  // ============================================================
  // REPORT EVIDENCE VERIFICATION
  // ============================================================

  Future<Map<String, dynamic>> verifyReportEvidence({
    required String disasterType,
     required File imageFile,
  }) async {
    final prompt = '''
You are the visual evidence verification AI for AEGIS AI.

Your task is NOT to decide whether a citizen report is true or false.

Analyze the disaster evidence associated with the report.

Reported disaster type:
$disasterType

Determine whether the available evidence is consistent with
the reported disaster type.

Evaluate:

- whether the evidence is relevant to the reported disaster
- whether visible evidence supports the disaster type
- whether the evidence appears unusable or unrelated
- quality of available evidence
- whether the evidence is strong, moderate, weak, or unavailable

IMPORTANT:

Do NOT use the citizen's description as proof.
Do NOT assume that a believable description means the report is genuine.
Do NOT declare the report definitely real or fake.
Do NOT invent facts that cannot be verified.
This result is an evidence assessment, NOT a final authenticity decision.

Return ONLY valid JSON in exactly this format:

{
  "evidenceScore": 85,
  "evidenceStatus": "STRONG",
  "imageRelevant": true,
  "reason": "Short explanation based only on available evidence."
}

Rules:

- evidenceScore must be an integer from 0 to 100.
- evidenceStatus must be exactly one of:
  STRONG, MODERATE, WEAK, UNAVAILABLE
- imageRelevant must be true or false.
- Do not include Markdown.
- Do not include ```json.
''';

    final imageBytes = await imageFile.readAsBytes();
final imagePart = InlineDataPart(
  'image/jpeg',
  imageBytes,
);

final response = await _model.generateContent([
  Content.multi([
    TextPart(prompt),
    imagePart,
  ]),
]);

    final text = response.text;

    if (text == null || text.trim().isEmpty) {
      throw Exception(
        'Gemini returned an empty evidence verification response.',
      );
    }

    String cleaned = text.trim();

    if (cleaned.startsWith('```json')) {
      cleaned = cleaned
          .replaceFirst('```json', '')
          .replaceFirst('```', '')
          .trim();
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst('```', '')
          .replaceFirst('```', '')
          .trim();
    }

    final decoded = jsonDecode(cleaned);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid evidence verification format.',
      );
    }

    if (decoded["evidenceScore"] == null ||
        decoded["evidenceStatus"] == null ||
        decoded["imageRelevant"] == null ||
        decoded["reason"] == null) {
      throw Exception(
        'Evidence verification is missing required fields.',
      );
    }

    return {
      "evidenceScore":
          (decoded["evidenceScore"] as num).toInt(),
      "evidenceStatus":
          decoded["evidenceStatus"].toString().toUpperCase(),
      "imageRelevant":
          decoded["imageRelevant"] == true,
      "reason":
          decoded["reason"].toString(),
    };
  }

  // ============================================================
  // SEVERITY VALIDATION
  // ============================================================

  Future<Map<String, dynamic>> generateSeverityValidation(
  String prompt,
) async {
  final response = await _model.generateContent([
    Content.text(prompt),
  ]);

    final text = response.text;

    if (text == null || text.trim().isEmpty) {
      throw Exception('Gemini returned an empty response.');
    }

    String cleaned = text.trim();

    if (cleaned.startsWith('```json')) {
      cleaned = cleaned
          .replaceFirst('```json', '')
          .replaceFirst('```', '')
          .trim();
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst('```', '')
          .replaceFirst('```', '')
          .trim();
    }

    final decoded = jsonDecode(cleaned);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid AI severity validation format.',
      );
    }

    if (decoded["reportedSeverity"] == null ||
        decoded["aiSeverity"] == null ||
        decoded["match"] == null ||
        decoded["confidence"] == null ||
        decoded["reason"] == null) {
      throw Exception(
        'AI severity validation is missing required fields.',
      );
    }

    return {
      "reportedSeverity":
          decoded["reportedSeverity"].toString(),
      "aiSeverity":
          decoded["aiSeverity"].toString(),
      "match":
          decoded["match"] == true,
      "confidence":
          (decoded["confidence"] as num).toInt(),
      "reason":
          decoded["reason"].toString(),
    };
  }
    Future<Map<String, dynamic>> analyzeCameraFrame(
    File imageFile,
  ) async {
    final prompt = '''
You are AEGIS AI, an emergency disaster detection system.

Analyze the camera image and identify visible emergency-related objects.

Look for:
- fire
- smoke
- vehicles
- debris
- collapsed structures
- other obvious hazards
- people

IMPORTANT PERSON DETECTION RULES:

- Detect EACH clearly visible person separately.
- Never use "crowd" as a label.
- If multiple people are visible, return multiple objects with label "person".
- Each person must have its own bounding box coordinates.
- Coordinates must be normalized between 0.0 and 1.0.
- x1,y1 = top-left of the person.
- x2,y2 = bottom-right of the person.
- Only create a person detection when an actual visible person can reasonably be identified.
- Do not detect a person merely because a screen, photo, poster, video, or text mentions people.
- If people cannot be individually identified, do not return fake person bounding boxes.

Return ONLY valid JSON in exactly this format:

{
  "summary": "Short description of what is visually visible",
  "riskLevel": "LOW",
  "detections": [
    {
      "label": "person",
      "confidence": 87,
      "x1": 0.30,
      "y1": 0.20,
      "x2": 0.50,
      "y2": 0.80
    },
    {
      "label": "person",
      "confidence": 91,
      "x1": 0.60,
      "y1": 0.20,
      "x2": 0.80,
      "y2": 0.80
    },
    {
      "label": "debris",
      "confidence": 94,
      "x1": 0.10,
      "y1": 0.70,
      "x2": 0.90,
      "y2": 0.95
    }
  ]
}

Rules:
- riskLevel must be exactly one of:
  LOW, MEDIUM, HIGH, CRITICAL
- riskLevel is an AI visual assessment of the image, not a real-time physical measurement.
- confidence must be an integer from 0 to 100.
- Only report objects actually visible in the image.
- Do not invent hidden people or objects.
- Return an empty detections list if nothing relevant is visible.
- Do not use Markdown.
- Do not include ```json.
''';

    final imageBytes = await imageFile.readAsBytes();

    final imagePart = InlineDataPart(
      'image/jpeg',
      imageBytes,
    );

    final response = await _model.generateContent([
      Content.multi([
        TextPart(prompt),
        imagePart,
      ]),
    ]);

    final text = response.text;

    if (text == null || text.trim().isEmpty) {
      throw Exception(
        'Gemini returned an empty camera analysis.',
      );
    }

    String cleaned = text.trim();

    if (cleaned.startsWith('```json')) {
      cleaned = cleaned
          .replaceFirst('```json', '')
          .replaceFirst('```', '')
          .trim();
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst('```', '')
          .replaceFirst('```', '')
          .trim();
    }

    final decoded = jsonDecode(cleaned);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid camera AI response format.',
      );
    }

    return decoded;
  }
  
}