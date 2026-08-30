class ReportModel {
  final String title;
  final String description;
  final String location;
  final String severity;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String status;
  final String? assignedTo;
  final DateTime createdAt;

  ReportModel({
    required this.title,
    required this.description,
    required this.location,
    required this.severity,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.assignedTo,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "description": description,
      "location": location,
      "severity": severity,
      "imageUrl": imageUrl,
      "latitude": latitude,
      "longitude": longitude,
      "status": status,
      "assignedTo": assignedTo,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      title: json["title"] ?? "",
      description: json["description"] ?? "",
      location: json["location"] ?? "",
      severity: json["severity"] ?? "",
      imageUrl: json["imageUrl"] ?? "",
      latitude: (json["latitude"] ?? 0).toDouble(),
      longitude: (json["longitude"] ?? 0).toDouble(),
      status: json["status"] ?? "Pending",
      assignedTo: json["assignedTo"],
      createdAt: DateTime.tryParse(
            json["createdAt"] ?? "",
          ) ??
          DateTime.now(),
    );
  }
}