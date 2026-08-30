import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/ai_service.dart';

class AIPriorityReportsScreen extends StatefulWidget {
  const AIPriorityReportsScreen({super.key});

  @override
  State<AIPriorityReportsScreen> createState() =>
      _AIPriorityReportsScreenState();
}

class _AIPriorityReportsScreenState
    extends State<AIPriorityReportsScreen> {

  final AIService _aiService = AIService();

  bool _analyzing = false;

  final Map<String, Map<String, dynamic>> _aiResults = {};

  Future<void> _analyzeReports(
    List<QueryDocumentSnapshot> reports,
  ) async {
    if (reports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No disaster reports available."),
        ),
      );
      return;
    }

    setState(() {
      _analyzing = true;
    });

    final reportData = reports.map((doc) {
  final data = doc.data() as Map<String, dynamic>;

  return {
    "id": doc.id,
    "title": data["title"]?.toString() ?? "",
    "description": data["description"]?.toString() ?? "",
    "disasterType": data["disasterType"]?.toString() ?? "",
    "severity": data["severity"]?.toString() ?? "",
    "location": data["location"]?.toString() ?? "",
  };
}).toList();

try {
  final results =
      await _aiService.analyzeDisasters(reportData);

  int successCount = 0;

  for (final result in results) {
    final index = result["reportIndex"] as int;

    if (index < 0 || index >= reports.length) {
      continue;
    }

    final doc = reports[index];

    _aiResults[doc.id] = {
      "priority": result["priority"],
      "score": result["score"],
      "reason": result["reason"],
    };

    await FirebaseFirestore.instance
        .collection("reports")
        .doc(doc.id)
        .update({
      "aiPriority": result["priority"],
      "aiPriorityScore": result["score"],
      "aiPriorityReason": result["reason"],
      "aiAnalyzedAt": FieldValue.serverTimestamp(),
    });

    successCount++;
  }
} catch (e) {
  debugPrint("AI batch analysis failed: $e");

  if (!mounted) return;

  setState(() {
    _analyzing = false;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("AI analysis failed: $e"),
    ),
  );
}
if (!mounted) return;

setState(() {
  _analyzing = false;
});

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      "AI analyzed ${reports.length} reports successfully.",
    ),
  ),
);
  }

  Color _priorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case "CRITICAL":
        return Colors.red;

      case "HIGH":
        return Colors.orange;

      case "MEDIUM":
        return Colors.amber.shade700;

      case "LOW":
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  IconData _priorityIcon(String priority) {
    switch (priority.toUpperCase()) {
      case "CRITICAL":
        return Icons.warning;

      case "HIGH":
        return Icons.priority_high;

      case "MEDIUM":
        return Icons.error_outline;

      case "LOW":
        return Icons.check_circle_outline;

      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text(
          "AI Priority Reports",
        ),
        backgroundColor:
            const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("reports")
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading reports:\n"
                "${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No disaster reports found.",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            );
          }

          final reports =
              snapshot.data!.docs.toList();

          reports.removeWhere((doc) {
            final data =
                doc.data()
                    as Map<String, dynamic>;

            return data["status"] ==
                "Resolved";
          });

          reports.sort((a, b) {
            final dataA =
                a.data()
                    as Map<String, dynamic>;

            final dataB =
                b.data()
                    as Map<String, dynamic>;

            final scoreA =
                _aiResults[a.id]?["score"] ??
                dataA["aiPriorityScore"] ??
                0;

            final scoreB =
                _aiResults[b.id]?["score"] ??
                dataB["aiPriorityScore"] ??
                0;

            return (scoreB as num)
                .compareTo(scoreA as num);
          });

          return Column(
            children: [

              Padding(
                padding:
                    const EdgeInsets.all(16),

                child: SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: FilledButton.icon(
                    onPressed: _analyzing
                        ? null
                        : () {
                            _analyzeReports(
                              reports,
                            );
                          },

                    icon: _analyzing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.psychology,
                          ),

                    label: Text(
                      _analyzing
                          ? "AI Analyzing..."
                          : "Analyze Reports With AI",
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: reports.isEmpty
                    ? const Center(
                        child: Text(
                          "No active disaster reports.",
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                        ),
                        itemCount:
                            reports.length,

                        itemBuilder:
                            (context, index) {

                          final doc =
                              reports[index];

                          final report =
                              doc.data()
                                  as Map<
                                      String,
                                      dynamic>;

                          final aiResult =
                              _aiResults[
                                  doc.id];

                          final priority =
                              aiResult?[
                                      "priority"] ??
                                  report[
                                      "aiPriority"];

                          final score =
                              aiResult?[
                                      "score"] ??
                                  report[
                                      "aiPriorityScore"];

                          final reason =
                              aiResult?[
                                      "reason"] ??
                                  report[
                                      "aiPriorityReason"];

                          final displayPriority =
                              priority ??
                                  "NOT ANALYZED";

                          final color =
                              _priorityColor(
                            displayPriority
                                .toString(),
                          );

                          return Card(
                            margin:
                                const EdgeInsets
                                    .only(
                              bottom: 12,
                            ),

                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets
                                      .all(16),

                              leading:
                                  CircleAvatar(
                                backgroundColor:
                                    color,

                                child: Icon(
                                  _priorityIcon(
                                    displayPriority
                                        .toString(),
                                  ),
                                  color:
                                      Colors.white,
                                ),
                              ),

                              title: Text(
                                report[
                                        "title"] ??
                                    "Disaster Report",
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  fontSize: 17,
                                ),
                              ),

                              subtitle:
                                  Padding(
                                padding:
                                    const EdgeInsets
                                        .only(
                                  top: 8,
                                ),

                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [

                                    Text(
                                      "📍 ${report["location"] ?? "Unknown location"}",
                                    ),

                                    const SizedBox(
                                      height: 5,
                                    ),

                                    Text(
                                      "🚨 ${report["disasterType"] ?? "Unknown"}",
                                    ),

                                    const SizedBox(
                                      height: 8,
                                    ),

                                    Text(
                                      "AI Priority: "
                                      "$displayPriority",
                                      style:
                                          TextStyle(
                                        color: color,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

if (report["aiSeverity"] != null)
  Text(
    "AI Severity: ${report["aiSeverity"]}",
    style: TextStyle(
      color: report["aiSeverityMatch"] == true
          ? Colors.green
          : Colors.red,
      fontWeight: FontWeight.bold,
    ),
  ),

if (report["aiSeverityConfidence"] != null)
  Text(
    "Severity Confidence: "
    "${report["aiSeverityConfidence"]}%",
  ),

                                    if (score != null)
                                      Text(
                                        "AI Score: "
                                        "$score / 100",
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .w600,
                                        ),
                                      ),

                                    if (reason !=
                                            null &&
                                        reason
                                            .toString()
                                            .isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets
                                                .only(
                                          top: 6,
                                        ),
                                        child: Text(
                                          "AI Reason: "
                                          "$reason",
                                        ),
                                      ),

                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}