import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'report_details_screen.dart';

class DisasterReportsScreen extends StatefulWidget {
  final String initialStatus;

  const DisasterReportsScreen({
    super.key,
    this.initialStatus = "All",
  });

  @override
  State<DisasterReportsScreen> createState() =>
      _DisasterReportsScreenState();
}

class _DisasterReportsScreenState
    extends State<DisasterReportsScreen> {

  String selectedStatus = "All";
  String searchText = "";

  @override
void initState() {
  super.initState();

  selectedStatus = widget.initialStatus;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Disaster Reports"),
      ),

      body: Column(
  children: [

    Padding(
      padding: const EdgeInsets.all(10),
      child: DropdownButtonFormField<String>(
        value: selectedStatus,
        decoration: const InputDecoration(
          labelText: "Filter by Status",
          border: OutlineInputBorder(),
        ),
        items: const [

          DropdownMenuItem(
            value: "All",
            child: Text("All Reports"),
          ),

          DropdownMenuItem(
            value: "Pending",
            child: Text("Pending"),
          ),

          DropdownMenuItem(
            value: "Assigned",
            child: Text("Assigned"),
          ),

          DropdownMenuItem(
            value: "In Progress",
            child: Text("In Progress"),
          ),
          DropdownMenuItem(
  value: "Completed",
  child: Text("Completed"),
),

          DropdownMenuItem(
            value: "Resolved",
            child: Text("Resolved"),
          ),

          DropdownMenuItem(
  value: "Needs Satellite",
  child: Text("Needs Satellite Verification"),
),

        ],
        onChanged: (value) {
          setState(() {
            selectedStatus = value!;
          });
        },
      ),
    ),
    Padding(
  padding: const EdgeInsets.symmetric(horizontal: 10),
  child: TextField(
    decoration: const InputDecoration(
      hintText: "Search by title or location",
      prefixIcon: Icon(Icons.search),
      border: OutlineInputBorder(),
    ),
    onChanged: (value) {
      setState(() {
        searchText = value.toLowerCase();
      });
    },
  ),
),

const SizedBox(height: 10),
    Expanded(
      child: StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection("reports")
      .orderBy("timestamp", descending: true)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
  return Center(
    child: Text(snapshot.error.toString()),
  );
}
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Center(
        child: Text("No reports found"),
      );
    }

    List<QueryDocumentSnapshot> reports =
    snapshot.data!.docs;

if (selectedStatus != "All") {
  if (selectedStatus == "Needs Satellite") {
  reports = reports.where((doc) {
    final data =
        doc.data() as Map<String, dynamic>;

    final satelliteAlreadyDone =
        data["satelliteVerification"] != null;

    if (satelliteAlreadyDone) {
      return false;
    }

    final disasterType =
        (data["disasterType"] ?? "")
            .toString()
            .toLowerCase();

    const satelliteNotSuitable = [
      "building collapse",
      "road accident",
      "accident",
      "person trapped",
      "missing person",
    ];

    for (final type in satelliteNotSuitable) {
      if (disasterType.contains(type)) {
        return false;
      }
    }

    return true;
  }).toList();
} else {
    reports = reports.where((doc) {
      return doc["status"] == selectedStatus;
    }).toList();
  }
}
  if (searchText.isNotEmpty) {

  reports = reports.where((doc) {

    final report =
        doc.data() as Map<String, dynamic>;

    final title =
        (report["title"] ?? "")
            .toString()
            .toLowerCase();

    final location =
        (report["location"] ?? "")
            .toString()
            .toLowerCase();

    return title.contains(searchText) ||
        location.contains(searchText);

  }).toList();

}
    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report =
    reports[index].data() as Map<String, dynamic>;

report["id"] = reports[index].id;

        return Card(
          margin: const EdgeInsets.all(10),
          child: ListTile(
            leading: const Icon(
              Icons.warning,
              color: Colors.red,
            ),
            title: Text(report["title"] ?? ""),
            subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(report["location"] ?? ""),

    const SizedBox(height: 5),

    if (report["satelliteVerification"] != null)
      const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.satellite_alt,
            size: 15,
            color: Colors.blue,
          ),
          SizedBox(width: 4),
          Text(
            "Satellite analyzed",
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
  ],
),
            trailing: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Text(
      report["severity"] ?? "",
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),

    const SizedBox(height: 4),

    Text(
      report["status"] ?? "Pending",
      style: TextStyle(
        color: report["status"] == "Completed"
            ? Colors.blue
            : report["status"] == "Resolved"
                ? Colors.green
                : Colors.grey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),

    if (report["satelliteVerification"] != null) ...[
      const SizedBox(height: 5),

      Builder(
        builder: (context) {
          final satellite =
              report["satelliteVerification"]
                  as Map<String, dynamic>?;

          final analysis =
              satellite?["finalAegisAnalysis"]
                  as Map<String, dynamic>?;

          final assessment =
              analysis?["overallAssessment"]
                  ?.toString();

          return Column(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Text(
      assessment ?? "Satellite analyzed",
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: assessment == "LIKELY_GENUINE"
            ? Colors.green
            : assessment == "LIKELY_SUSPICIOUS"
                ? Colors.red
                : Colors.orange,
      ),
    ),

    if (selectedStatus == "Needs Satellite") ...[
      const SizedBox(height: 4),

      Text(
        _satelliteReason(
          report["disasterType"]?.toString() ?? "",
        ),
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.grey,
        ),
      ),
    ],
  ],
);
        },
      ),
    ],
  ],
),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportDetailsScreen(
                    report: report,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
   },
),
    ),
  ],
),
    );
  }
  String _satelliteReason(String disasterType) {
  final type = disasterType.toLowerCase();

  if (type.contains("flood")) {
    return "Satellite: useful for large-area water change";
  }

  if (type.contains("landslide")) {
    return "Satellite: useful for large terrain change";
  }

  if (type.contains("fire") ||
      type.contains("wildfire")) {
    return "Satellite: useful for large burn-area change";
  }

  if (type.contains("drought")) {
    return "Satellite: useful for large-area surface change";
  }

  if (type.contains("cyclone") ||
      type.contains("storm")) {
    return "Satellite: supplementary environmental evidence";
  }

  return "Satellite: supplementary evidence";
}
}