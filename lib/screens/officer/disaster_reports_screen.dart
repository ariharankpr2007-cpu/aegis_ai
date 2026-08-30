import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'report_details_screen.dart';

class DisasterReportsScreen extends StatefulWidget {
  const DisasterReportsScreen({super.key});

  @override
  State<DisasterReportsScreen> createState() =>
      _DisasterReportsScreenState();
}

class _DisasterReportsScreenState
    extends State<DisasterReportsScreen> {

  String selectedStatus = "All";
  String searchText = "";

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

  reports = reports.where((doc) {

    return doc["status"] == selectedStatus;

  }).toList();

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
            subtitle: Text(report["location"] ?? ""),
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
}