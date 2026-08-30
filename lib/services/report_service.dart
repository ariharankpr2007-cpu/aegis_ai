import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/report_model.dart';

class ReportService {
  static const String storageKey = "saved_reports";

  static Future<void> saveReport(ReportModel report) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> reports =
        prefs.getStringList(storageKey) ?? [];

    reports.add(jsonEncode(report.toJson()));

    await prefs.setStringList(storageKey, reports);
  }

  static Future<List<ReportModel>> getReports() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> reports =
        prefs.getStringList(storageKey) ?? [];

    return reports
        .map(
          (e) => ReportModel.fromJson(
            jsonDecode(e),
          ),
        )
        .toList();
  }

  static Future<void> deleteReport(int index) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> reports =
        prefs.getStringList(storageKey) ?? [];

    reports.removeAt(index);

    await prefs.setStringList(storageKey, reports);
  }

  static Future<void> clearReports() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(storageKey);
  }
}