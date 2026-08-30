import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'emergency_response_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .where("receiverId", isEqualTo: uid)
            .orderBy("timestamp", descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No Notifications",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final notifications =
              snapshot.data!.docs;
              for (var doc in notifications) {

  if ((doc["isRead"] ?? false) == false) {

    FirebaseFirestore.instance
        .collection("notifications")
        .doc(doc.id)
        .update({

      "isRead": true,

    });

  }

}

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {

              final data =
                  notifications[index].data()
                      as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),

                child: ListTile(

                  leading: CircleAvatar(
  backgroundColor:

      data["type"] == "assignment"

          ? Colors.orange

          : data["type"] == "completed"

              ? Colors.green

              : Colors.blue,

  child: Icon(

    data["type"] == "assignment"

        ? Icons.assignment

        : data["type"] == "completed"

            ? Icons.check_circle

            : Icons.notifications,

    color: Colors.white,

  ),
),

                  title: Text(
  data["title"] ?? "",
),

subtitle: Text(
  data["body"] ?? "",
),

onTap: () {
  if (data["type"] == "emergency_alert") {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmergencyResponseScreen(
          reportId: data["reportId"],
          notificationId: notifications[index].id,
        ),
      ),
    );
  }
},

),
              );

            },
          );

        },
      ),
    );
  }
}