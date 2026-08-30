import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Disaster Analytics"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("reports")
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final reports = snapshot.data!.docs;

          int flood = 0;
          int fire = 0;
          int earthquake = 0;
          int cyclone = 0;
          int landslide = 0;

          for (var doc in reports) {

            final report =
                doc.data() as Map<String, dynamic>;

            switch (report["disasterType"]) {

              case "Flood":
                flood++;
                break;

              case "Fire":
                fire++;
                break;

              case "Earthquake":
                earthquake++;
                break;

              case "Cyclone":
                cyclone++;
                break;

              case "Landslide":
                landslide++;
                break;

            }
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [

              analyticsCard(
                  "Flood", flood, Colors.blue),

              analyticsCard(
                  "Fire", fire, Colors.red),

              analyticsCard(
                  "Earthquake",
                  earthquake,
                  Colors.orange),

              analyticsCard(
                  "Cyclone",
                  cyclone,
                  Colors.green),

              analyticsCard(
                  "Landslide",
                  landslide,
                  Colors.brown),

            ],
          );
        },
      ),
    );
  }

  Widget analyticsCard(
      String title,
      int value,
      Color color,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
        ),
        title: Text(title),
        trailing: Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}