import 'dart:async';
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class BroadcastAlertScreen extends StatefulWidget {
  const BroadcastAlertScreen({super.key});

  @override
  State<BroadcastAlertScreen> createState() =>
      _BroadcastAlertScreenState();
}

class _BroadcastAlertScreenState
    extends State<BroadcastAlertScreen> {
  final titleController = TextEditingController();
  final messageController = TextEditingController();
  final locationController = TextEditingController();

  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final mapController = MapController();

  Timer? searchTimer;

  String selectedPriority = "High";
  String selectedAlertType = "Flood";

  LatLng selectedLocation = const LatLng(13.0827, 80.2707);

  List<Map<String, dynamic>> suggestions = [];

  bool isSearching = false;
  bool isBroadcasting = false;

  Future<void> searchLocations(String query) async {
    searchTimer?.cancel();

    if (query.trim().length < 3) {
      setState(() {
        suggestions = [];
      });
      return;
    }

    searchTimer = Timer(
      const Duration(milliseconds: 600),
      () async {
        setState(() {
          isSearching = true;
        });

        try {
          final uri = Uri.https(
            "nominatim.openstreetmap.org",
            "/search",
            {
              "q": query.trim(),
              "format": "jsonv2",
              "limit": "5",
              "addressdetails": "1",
            },
          );

          final response = await http.get(
            uri,
            headers: {
              "User-Agent": "aegis_ai_emergency_app",
            },
          );

          if (response.statusCode == 200) {
            final data =
                jsonDecode(response.body) as List<dynamic>;

            if (!mounted) return;

            setState(() {
              suggestions = data
                  .map(
                    (item) => {
                      "display_name":
                          item["display_name"] ?? "",
                      "lat": item["lat"],
                      "lon": item["lon"],
                    },
                  )
                  .toList();
            });
          }
        } catch (error) {
          debugPrint("Location search error: $error");
        } finally {
          if (mounted) {
            setState(() {
              isSearching = false;
            });
          }
        }
      },
    );
  }

  void chooseSuggestion(Map<String, dynamic> suggestion) {
  if (!mounted) return;

  final latitude = double.tryParse(
    suggestion["lat"].toString(),
  );

  final longitude = double.tryParse(
    suggestion["lon"].toString(),
  );

  if (latitude == null || longitude == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Invalid location selected"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final point = LatLng(latitude, longitude);

  setState(() {
    selectedLocation = point;
    locationController.text =
        suggestion["display_name"].toString();
    suggestions = [];
  });

  FocusScope.of(context).unfocus();
  mapController.move(point, 15);
}

  Future<void> chooseLocationFromMap(LatLng point) async {
  setState(() {
    selectedLocation = point;
    locationController.text =
        "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
  });

  mapController.move(point, 15);

  try {
    final placemarks = await placemarkFromCoordinates(
      point.latitude,
      point.longitude,
    );

    if (placemarks.isNotEmpty && mounted) {
      final place = placemarks.first;

      final readableAddress = [
        place.name,
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.postalCode,
      ]
          .where((value) => value != null && value.trim().isNotEmpty)
          .join(", ");

      setState(() {
        locationController.text = readableAddress.isNotEmpty
            ? readableAddress
            : "${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}";
      });
    }
  } catch (e) {
    debugPrint("Reverse geocoding failed: $e");
  }
}

  Future<void> useCurrentLocation() async {
  try {
    if (!mounted) return;

setState(() {
  isSearching = true;
});

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enable GPS/location service"),
        ),
      );

      return;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location permission denied"),
        ),
      );

      return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Location permission permanently denied. "
            "Enable it from app settings.",
          ),
        ),
      );

      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    final point = LatLng(
      position.latitude,
      position.longitude,
    );

    String placeName =
        "${position.latitude.toStringAsFixed(6)}, "
        "${position.longitude.toStringAsFixed(6)}";

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        placeName = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ]
            .where(
              (value) =>
                  value != null &&
                  value.trim().isNotEmpty,
            )
            .join(", ");
      }
    } catch (error) {
      debugPrint("Reverse geocoding error: $error");
    }

    if (!mounted) return;

    setState(() {
      selectedLocation = point;
      locationController.text = placeName;
      suggestions = [];
    });

    mapController.move(point, 16);
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Unable to get current location: $error"),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
  if (!mounted) return;

  setState(() {
    isSearching = false;
  });
}
}

  Future<void> broadcastAlert() async {
    final title = titleController.text.trim();
    final message = messageController.text.trim();
    final location = locationController.text.trim();

    if (title.isEmpty ||
        message.isEmpty ||
        location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields"),
        ),
      );
      return;
    }

    setState(() {
      isBroadcasting = true;
    });

    try {
      await firestore.collection("broadcast_alerts").add({
        "title": title,
        "message": message,
        "priority": selectedPriority,
        "alertType": selectedAlertType,
        "location": location,
        "latitude": selectedLocation.latitude,
        "longitude": selectedLocation.longitude,
        "status": "Active",
        "createdBy": auth.currentUser?.uid,
        "createdAt": Timestamp.now(),
      });

      if (!mounted) return;

      titleController.clear();
      messageController.clear();
      locationController.clear();

      setState(() {
        selectedPriority = "High";
        selectedAlertType = "Flood";
        selectedLocation =
            const LatLng(13.0827, 80.2707);
        suggestions = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Emergency Alert Broadcast Successfully",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to broadcast alert: $error"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isBroadcasting = false;
        });
      }
    }
  }

  Future<void> resolveAlert(String alertId) async {
  try {
    await firestore
        .collection("broadcast_alerts")
        .doc(alertId)
        .update({
      "status": "Resolved",
      "resolvedAt": Timestamp.now(),
      "resolvedBy": auth.currentUser?.uid,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Emergency alert marked as Resolved"),
        backgroundColor: Colors.green,
      ),
    );
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to resolve alert: $error"),
        backgroundColor: Colors.red,
      ),
    );
  }
}
Future<void> archiveAlert(String alertId) async {
  try {
    await firestore
        .collection("broadcast_alerts")
        .doc(alertId)
        .update({
      "status": "Archived",
      "archivedAt": Timestamp.now(),
      "archivedBy": auth.currentUser?.uid,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Emergency alert archived"),
        backgroundColor: Colors.blue,
      ),
    );
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to archive alert: $error"),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  void dispose() {
    searchTimer?.cancel();
    titleController.dispose();
    messageController.dispose();
    locationController.dispose();
    super.dispose();
  }

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Alert Title",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: "Example: Flood Warning",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Alert Message",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText:
                    "Enter emergency instructions for citizens",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Priority",
              style: TextStyle(fontWeight: FontWeight.bold),
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

            const SizedBox(height: 20),

            const Text(
              "Alert Type",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedAlertType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: "Flood",
                  child: Text("Flood"),
                ),
                DropdownMenuItem(
                  value: "Cyclone",
                  child: Text("Cyclone"),
                ),
                DropdownMenuItem(
                  value: "Fire",
                  child: Text("Fire"),
                ),
                DropdownMenuItem(
                  value: "Accident",
                  child: Text("Accident"),
                ),
                DropdownMenuItem(
                  value: "Missing Person",
                  child: Text("Missing Person"),
                ),
                DropdownMenuItem(
                  value: "Medical Emergency",
                  child: Text("Medical Emergency"),
                ),
                DropdownMenuItem(
                  value: "Road Blockage",
                  child: Text("Road Blockage"),
                ),
                DropdownMenuItem(
                  value: "General Emergency",
                  child: Text("General Emergency"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedAlertType = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            const Text(
              "Affected Location",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
  controller: locationController,
  onChanged: (value) {
  setState(() {});
  searchLocations(value);
},
  decoration: InputDecoration(
    hintText: "Search location",
    border: const OutlineInputBorder(),
    prefixIcon: const Icon(Icons.location_on),
    suffixIcon: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (locationController.text.isNotEmpty)
          IconButton(
            tooltip: "Clear location",
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                locationController.clear();
                suggestions = [];
                selectedLocation =
                    const LatLng(13.0827, 80.2707);
              });

              mapController.move(
                const LatLng(13.0827, 80.2707),
                13,
              );
            },
          ),
        IconButton(
          tooltip: "Use current location",
          icon: const Icon(
            Icons.my_location,
            color: Colors.blue,
          ),
          onPressed: isSearching
              ? null
              : useCurrentLocation,
        ),
      ],
    ),
  ),
),

const SizedBox(height: 8),

SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: isSearching
        ? null
        : useCurrentLocation,
    icon: const Icon(Icons.my_location),
    label: const Text("Use My Current Location"),
  ),
),

            if (suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: suggestions.map((suggestion) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                      ),
                      title: Text(
                        suggestion["display_name"].toString(),
                      ),
                      onTap: () {
                        chooseSuggestion(suggestion);
                      },
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 12),

            SizedBox(
              height: 280,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
  initialCenter: selectedLocation,
  initialZoom: 13,
  minZoom: 3,
  maxZoom: 18,
  onTap: (tapPosition, point) {
    chooseLocationFromMap(point);
  },
),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName:
                          "com.example.aegis_ai",
                          maxZoom: 18,
  keepBuffer: 1,
  panBuffer: 0,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selectedLocation,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Tap the map to place the red marker manually.",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton.icon(
                onPressed:
                    isBroadcasting ? null : broadcastAlert,
                icon: isBroadcasting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.campaign),
                label: Text(
                  isBroadcasting
                      ? "Broadcasting..."
                      : "Broadcast Alert",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 30),

const Text(
  "Active Emergency Alerts",
  style: TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 12),

StreamBuilder<QuerySnapshot>(
  stream: firestore
      .collection("broadcast_alerts")
      .where("status", isEqualTo: "Active")
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (snapshot.hasError) {
      return Text(
        "Failed to load alerts: ${snapshot.error}",
      );
    }

    final docs = snapshot.data?.docs ?? [];

    if (docs.isEmpty) {
      return const Text(
        "No active emergency alerts.",
      );
    }

    return Column(
      children: docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        final title =
            data["title"]?.toString() ?? "Untitled alert";

        final priority =
            data["priority"]?.toString() ?? "Low";

        final message =
            data["message"]?.toString() ?? "";

        final color = priority == "High"
            ? Colors.red
            : priority == "Medium"
                ? Colors.orange
                : Colors.green;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              Icons.warning_amber_rounded,
              color: color,
            ),
            title: Text(title),
            subtitle: Text(
              "$priority priority\n$message",
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            isThreeLine: true,
            trailing: TextButton(
              onPressed: () => resolveAlert(doc.id),
              child: const Text("Resolve"),
            ),
          ),
        );
      }).toList(),
    );
  },
),
const SizedBox(height: 30),

const Text(
  "Resolved Emergency Alerts",
  style: TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 12),

StreamBuilder<QuerySnapshot>(
  stream: firestore
      .collection("broadcast_alerts")
      .where("status", isEqualTo: "Resolved")
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (snapshot.hasError) {
      return Text(
        "Failed to load resolved alerts: ${snapshot.error}",
      );
    }

    final docs = snapshot.data?.docs ?? [];

    if (docs.isEmpty) {
      return const Text(
        "No resolved emergency alerts.",
      );
    }

    return Column(
      children: docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        final title =
            data["title"]?.toString() ?? "Untitled alert";

        final message =
            data["message"]?.toString() ?? "";

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
            title: Text(title),
            subtitle: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: TextButton(
              onPressed: () => archiveAlert(doc.id),
              child: const Text("Archive"),
            ),
          ),
        );
      }).toList(),
    );
  },
),
          ],
        ),
      ),
    );
  }
}