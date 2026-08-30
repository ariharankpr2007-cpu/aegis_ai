import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfficerImportScreen extends StatefulWidget {
  const OfficerImportScreen({super.key});

  @override
  State<OfficerImportScreen> createState() =>
      _OfficerImportScreenState();
}

class _OfficerImportScreenState
    extends State<OfficerImportScreen> {
  bool importing = false;
  String statusMessage = "";

  Future<void> importOfficers() async {
    setState(() {
      importing = true;
      statusMessage = "";
    });

    try {
      final result =
    await FilePicker.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['csv'],
);

      if (result == null) {
        setState(() {
          importing = false;
        });
        return;
      }

      final path = result.files.single.path;

      if (path == null) {
        throw Exception(
          "Unable to access the selected CSV file.",
        );
      }

      final file = File(path);

      final csvText = await file.readAsString();

      final rows =
          const CsvToListConverter().convert(csvText);

      if (rows.isEmpty) {
        throw Exception(
          "The CSV file is empty.",
        );
      }

      final headers = rows.first
          .map(
            (value) =>
                value.toString().trim().toLowerCase(),
          )
          .toList();

      final requiredHeaders = [
        "officerid",
        "name",
        "department",
        "state",
        "district",
      ];

      for (final header in requiredHeaders) {
        if (!headers.contains(header)) {
          throw Exception(
            "Missing required column: $header",
          );
        }
      }

      final officerIdIndex =
          headers.indexOf("officerid");

      final nameIndex =
          headers.indexOf("name");

      final departmentIndex =
          headers.indexOf("department");

      final stateIndex =
          headers.indexOf("state");

      final districtIndex =
          headers.indexOf("district");

      int imported = 0;
      int skipped = 0;

      final collection = FirebaseFirestore.instance
          .collection("officerRegistry");

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        if (row.length <= districtIndex) {
          skipped++;
          continue;
        }

        final officerId =
            row[officerIdIndex].toString().trim();

        final name =
            row[nameIndex].toString().trim();

        final department =
            row[departmentIndex].toString().trim();

        final state =
            row[stateIndex].toString().trim();

        final district =
            row[districtIndex].toString().trim();

        if (officerId.isEmpty ||
            name.isEmpty ||
            department.isEmpty ||
            state.isEmpty ||
            district.isEmpty) {
          skipped++;
          continue;
        }

        await collection.doc(
          officerId.toUpperCase(),
        ).set({
          "name": name,
          "department": department,
          "state": state,
          "district": district,
          "active": true,
          "importedAt": Timestamp.now(),
        });

        imported++;
      }

      if (!mounted) return;

      setState(() {
        importing = false;
        statusMessage =
            "Import completed.\n"
            "Officers imported: $imported\n"
            "Rows skipped: $skipped";
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        importing = false;
        statusMessage =
            "Import failed:\n${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Officer Import",
        ),
        backgroundColor:
            const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              "Import Officers",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Upload an authorized officer CSV file "
              "to create officer registry records automatically.",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Text(
                "CSV columns required:\n\n"
                "officerId, name, department, state, district",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    importing
                        ? null
                        : importOfficers,
                icon: importing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.upload_file,
                      ),
                label: Text(
                  importing
                      ? "Importing..."
                      : "Select CSV & Import",
                ),
              ),
            ),

            const SizedBox(height: 25),

            if (statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: Text(
                  statusMessage,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}