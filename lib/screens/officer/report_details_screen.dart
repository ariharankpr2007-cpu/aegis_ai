import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> report;

  const ReportDetailsScreen({
    super.key,
    required this.report,
  });

  @override
  State<ReportDetailsScreen> createState() =>
      _ReportDetailsScreenState();
}

class _ReportDetailsScreenState
    extends State<ReportDetailsScreen> {

  String? selectedRescueId;
  String? selectedRescueName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Details"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

           Center(
  child: widget.report["imageUrl"] != null &&
          widget.report["imageUrl"] != ""
      ? ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            widget.report["imageUrl"],
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        )
      : const Icon(
          Icons.image,
          size: 120,
        ),
),

            const SizedBox(height: 20),

            Text(
              widget.report["title"] ?? "",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Text("📍 Location : ${widget.report["location"]}"),

            const SizedBox(height: 10),

            Text("🌊 Type : ${widget.report["disasterType"]}"),

            const SizedBox(height: 10),

            Text("🚨 Severity : ${widget.report["severity"]}"),
            const SizedBox(height: 10),

Text(
  "📌 Status : ${widget.report["status"] ?? "Pending"}",
  style: const TextStyle(
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 15),

if (widget.report["evidenceStatus"] != null)
  Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🛡️ Evidence Verification",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "Evidence Score: "
            "${widget.report["evidenceScore"] ?? 0}/100",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Status: "
            "${widget.report["evidenceStatus"] ?? "UNAVAILABLE"}",
          ),

          const SizedBox(height: 8),

          Text(
            "Image Relevant: "
            "${widget.report["imageRelevant"] == true ? "Yes" : "No"}",
          ),

          const SizedBox(height: 10),

          Text(
            "AI Assessment: "
            "${widget.report["evidenceReason"] ?? "No assessment available."}",
          ),
        ],
      ),
    ),
  ),

const SizedBox(height: 10),
if (widget.report["verificationStatus"] != "Verified")
  Column(
    children: [
      const SizedBox(height: 10),

      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.verified),
          label: const Text("Verify Report"),
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection("reports")
                .doc(widget.report["id"])
                .update({
              "verificationStatus": "Verified",
              "verifiedByOfficer": true,
              "verifiedAt": Timestamp.now(),
            });

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Report verified successfully."),
              ),
            );

            Navigator.pop(context);
          },
        ),
      ),

      const SizedBox(height: 8),

      SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.warning_amber_rounded),
          label: const Text("Mark Suspicious"),
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection("reports")
                .doc(widget.report["id"])
                .update({
              "verificationStatus": "Suspicious",
              "verifiedByOfficer": true,
              "verifiedAt": Timestamp.now(),
            });

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Report marked as suspicious."),
              ),
            );

            Navigator.pop(context);
          },
        ),
      ),

      const SizedBox(height: 8),

      SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.cancel),
          label: const Text("Mark False"),
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection("reports")
                .doc(widget.report["id"])
                .update({
              "verificationStatus": "False",
              "verifiedByOfficer": true,
              "verifiedAt": Timestamp.now(),
            });

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Report marked as false."),
              ),
            );

            Navigator.pop(context);
          },
        ),
      ),

      const SizedBox(height: 20),
    ],
  ),

if (widget.report["assignedName"] != null)

Text(
  "🚑 Rescue Team : ${widget.report["assignedName"]}",
  style: const TextStyle(
    color: Colors.green,
    fontWeight: FontWeight.bold,
  ),
),

            const SizedBox(height: 20),

            const Text(
              "Description",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(widget.report["description"] ?? ""),

const SizedBox(height: 30),

// ================= AI SEVERITY VALIDATION =================

if (widget.report["aiSeverity"] != null) ...[
  Card(
    color: widget.report["aiSeverityMatch"] == true
        ? Colors.green.shade50
        : Colors.orange.shade50,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Icon(
                widget.report["aiSeverityMatch"] == true
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
                color:
                    widget.report["aiSeverityMatch"] == true
                        ? Colors.green
                        : Colors.orange,
              ),

              const SizedBox(width: 8),

              const Expanded(
                child: Text(
                  "AI Severity Validation",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            "Reported Severity : "
            "${widget.report["severity"] ?? "Unknown"}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "AI Assessment : "
            "${widget.report["aiSeverity"] ?? "Unknown"}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  widget.report["aiSeverityMatch"] == true
                      ? Colors.green
                      : Colors.red,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "AI Confidence : "
            "${widget.report["aiSeverityConfidence"] ?? 0}%",
          ),

          const SizedBox(height: 15),

          Text(
            widget.report["aiSeverityMatch"] == true
                ? "✓ AI assessment matches the reported severity."
                : "⚠ AI assessment differs from the reported severity.",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  widget.report["aiSeverityMatch"] == true
                      ? Colors.green
                      : Colors.orange.shade800,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            widget.report["aiSeverityReason"] ??
                "No AI explanation available.",
          ),
        ],
      ),
    ),
  ),

  const SizedBox(height: 20),
],
// ================= AI AUTOMATIC ASSIGNMENT =================

if (widget.report["aiAssigned"] == true) ...[
  Card(
    color: Colors.green.shade50,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Row(
            children: [
              Icon(
                Icons.smart_toy,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "AI Automatic Assignment",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            "🚑 Rescue Team : "
            "${widget.report["assignedName"] ?? "Unknown"}",
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "AI Reason : "
            "${widget.report["aiAssignmentReason"] ?? "No reason available."}",
          ),

          const SizedBox(height: 12),

          const Text(
            "✓ This rescue team was automatically selected "
            "by AEGIS AI.",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    ),
  ),

  const SizedBox(height: 20),
],
if (widget.report["aiAssigned"] != true) ...[
  const Text(
    "Select Rescue Team",
    style: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),

  const SizedBox(height: 10),

  StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("rescueTeams")
        .where(
          "status",
          isEqualTo: "Available",
        )
        .where(
          "isApproved",
          isEqualTo: true,
        )
        .snapshots(),

    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const CircularProgressIndicator();
      }

      final rescueTeams = snapshot.data!.docs;

      return DropdownButtonFormField<String>(
        value: selectedRescueId,

        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),

        hint: const Text(
          "Choose Rescue Team",
        ),

        items: rescueTeams.map((doc) {
          final data =
              doc.data() as Map<String, dynamic>;

          return DropdownMenuItem<String>(
            value: doc.id,
            child: Text(
              data["name"] ?? "Rescue Team",
            ),
          );
        }).toList(),

        onChanged: (value) {
          if (value == null) return;

          setState(() {
            selectedRescueId = value;

            final selectedDoc =
                rescueTeams.firstWhere(
              (doc) => doc.id == value,
            );

            final data =
                selectedDoc.data()
                    as Map<String, dynamic>;

            selectedRescueName = data["name"];
          });
        },
      );
    },
  ),

  const SizedBox(height: 25),

  SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: () async {
        if (selectedRescueId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Select a Rescue Team",
              ),
            ),
          );

          return;
        }

        await FirebaseFirestore.instance
            .collection("reports")
            .doc(widget.report["id"])
            .update({
          "assignedTo": selectedRescueId,
          "assignedName": selectedRescueName,
          "status": "Assigned",
        });

        await FirebaseFirestore.instance
            .collection("notifications")
            .add({
          "receiverId": selectedRescueId,
          "title": "🚑 New Mission Assigned",
          "body":
              "You have been assigned to '${widget.report["title"]}'.",
          "type": "assignment",
          "isRead": false,
          "timestamp": Timestamp.now(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Rescue Team Assigned",
            ),
          ),
        );

        Navigator.pop(context);
      },

      child: const Text(
        "Assign Rescue Team",
      ),
    ),
  ),
],

                    const SizedBox(height: 15),
  SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    onPressed: () async {
      final reportId = widget.report["id"];

      await FirebaseFirestore.instance
          .collection("reports")
          .doc(reportId)
          .update({
        "status": "Resolved",
        "verifiedAt": Timestamp.now(),
      });

      final assignedTo = widget.report["assignedTo"];

      if (assignedTo != null &&
          assignedTo.toString().isNotEmpty) {
        await FirebaseFirestore.instance
            .collection("notifications")
            .add({
          "receiverId": assignedTo,
          "title": "✅ Mission Verified",
          "body":
              "Your mission '${widget.report["title"] ?? "mission"}' "
              "has been verified and resolved by the officer.",
          "type": "mission_resolved",
          "reportId": reportId,
          "isRead": false,
          "timestamp": Timestamp.now(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Mission verified and report resolved",
          ),
        ),
      );

      Navigator.pop(context);
    },
        child: Text(
      widget.report["status"] == "Completed"
          ? "Verify & Resolve"
          : "Mark as Resolved",
    ),
  ),
),
      ],
        
    ),
  ),
);
  }
}