import 'package:flutter/material.dart';

class BroadcastAlertScreen extends StatefulWidget {
  const BroadcastAlertScreen({super.key});

  @override
  State<BroadcastAlertScreen> createState() =>
      _BroadcastAlertScreenState();
}

class _BroadcastAlertScreenState
    extends State<BroadcastAlertScreen> {

  final TextEditingController titleController =
      TextEditingController();

  final TextEditingController messageController =
      TextEditingController();

  String selectedPriority = "High";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Broadcast Alert"),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              "Alert Title",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: "Enter alert title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Alert Message",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Enter emergency message",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Priority",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedPriority,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [

                DropdownMenuItem(
                  value: "High",
                  child: Text("High"),
                ),

                DropdownMenuItem(
                  value: "Medium",
                  child: Text("Medium"),
                ),

                DropdownMenuItem(
                  value: "Low",
                  child: Text("Low"),
                ),

              ],
              onChanged: (value) {
                setState(() {
                  selectedPriority = value!;
                });
              },
            ),

            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Emergency Alert Broadcast Successfully"),
                    ),
                  );

                  titleController.clear();
                  messageController.clear();

                  setState(() {
                    selectedPriority = "High";
                  });
                },
                icon: const Icon(Icons.campaign),
                label: const Text(
                  "Broadcast Alert",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}