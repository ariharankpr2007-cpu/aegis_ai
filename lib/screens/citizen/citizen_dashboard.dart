import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/ai_service.dart';
import 'report_disaster_screen.dart';
import 'report_history_screen.dart';
import 'alerts_screen.dart';
import 'emergency_contacts_screen.dart';
import 'location_screen.dart';
import 'learning_hub_screen.dart';
import 'live_stream_screen.dart';
import 'medical_profile_screen.dart';
import 'sos_screen.dart';
import 'shelter_screen.dart';
import 'weather_screen.dart';
import 'report_screen.dart';
import '../common/notification_screen.dart';
import '../common/session_actions.dart';
import '../common/settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() =>
      _CitizenDashboardState();
}

class _CitizenDashboardState
    extends State<CitizenDashboard> {
      final AIService _aiService = AIService();

Map<String, dynamic>? _weather;

bool _weatherLoading = true;

String _weatherError = "";

@override
void initState() {
  super.initState();
  _loadLiveWeather();
}

Future<void> _loadLiveWeather() async {
  try {
    final position =
        await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    final weather =
        await _aiService.getWeatherEvidence(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (!mounted) return;

    setState(() {
      _weather = weather;
      _weatherLoading = false;
      _weatherError = "";
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _weatherLoading = false;
      _weatherError =
          "Unable to load live weather";
    });
  }
}

  static const _navy = Color(0xFF0B3D91);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('AEGIS AI'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
           onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const NotificationScreen(),
    ),
  );
},
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Citizen')),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => SessionActions.confirmLogout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hello 👋',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Stay safe. Help is one tap away.',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 20),
            _SafetyStatusCard(
  weather: _weather,
  loading: _weatherLoading,
  error: _weatherError,
),
const SizedBox(height: 18),

_BroadcastAlertsCard(),
            const SizedBox(height: 22),
            _SosButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SosScreen()),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Quick actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.12,
              children: [
                _DashboardItem(
                  icon: Icons.report_outlined,
                  title: 'Report Disaster',
                  color: Colors.red,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReportDisasterScreen()),
                  ),
                ),
                _DashboardItem(
                  icon: Icons.history_outlined,
                  title: 'My Reports',
                  color: Colors.brown,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReportHistoryScreen()),
                  ),
                ),
                _DashboardItem(
                  icon: Icons.location_on_outlined,
                  title: 'Live Location',
                  color: Colors.green,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LocationScreen()),
                  ),
                ),
                _DashboardItem(
                  icon: Icons.videocam_outlined,
                  title: 'Live Stream',
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LiveStreamScreen()),
                  ),
                ),
                _DashboardItem(
                  icon: Icons.cloud_outlined,
                  title: 'Weather & Risk',
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WeatherScreen()),
                  ),
                ),
                _DashboardItem(
                  icon: Icons.home_work_outlined,
                  title: 'Shelters',
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShelterScreen()),
                  ),
                ),
                _DashboardItem(
                  icon: Icons.notifications_active_outlined,
                  title: 'Alerts',
                  color: Colors.deepPurple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AlertsScreen()),
                  ),
                ),
                _DashboardItem(
                  icon: Icons.medical_information_outlined,
                  title: 'Medical Profile',
                  color: Colors.pink,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MedicalProfileScreen()),
                  ),
                ),
                _DashboardItem(
                  icon: Icons.phone_in_talk_outlined,
                  title: 'Emergency Contacts',
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
                  ),
                ),
                _DashboardItem(
                  icon: Icons.school_outlined,
                  title: 'Learning Hub',
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LearningHubScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be added next.')),
    );
  }
}

class _SafetyStatusCard extends StatelessWidget {
  const _SafetyStatusCard({
    required this.weather,
    required this.loading,
    required this.error,
  });

  final Map<String, dynamic>? weather;
  final bool loading;
  final String error;

  String _weatherDescription(dynamic code) {
    if (code == null) {
      return "Unavailable";
    }

    final value = (code as num).toInt();

    if (value == 0) return "Clear";
    if (value <= 3) return "Partly cloudy";
    if (value <= 48) return "Fog";
    if (value <= 57) return "Drizzle";
    if (value <= 67) return "Rain";
    if (value <= 77) return "Snow";
    if (value <= 82) return "Rain showers";
    if (value <= 86) return "Snow showers";
    if (value >= 95) return "Thunderstorm";

    return "Changing conditions";
  }

  @override
  Widget build(BuildContext context) {
    final temperature =
        weather?["temperature"];

    final humidity =
        weather?["humidity"];

    final rain =
        weather?["rain"];

    final precipitation =
        weather?["precipitation"];

    final wind =
        weather?["windSpeed"];

    final rainfallLast24 =
        weather?["rainfallLast24Hours"];

    final weatherCode =
        weather?["weatherCode"];

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              "Live Safety Status",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            if (loading)
              const Center(
                child: Padding(
                  padding:
                      EdgeInsets.all(15),
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (error.isNotEmpty)
              Text(
                error,
                style: const TextStyle(
                  color: Colors.red,
                ),
              )
            else ...[
              _StatusRow(
                Icons.cloud_outlined,
                Colors.blue,
                'Weather',
                _weatherDescription(
                  weatherCode,
                ),
              ),

              const SizedBox(height: 11),

              _StatusRow(
                Icons.thermostat_outlined,
                Colors.orange,
                'Temperature',
                temperature == null
                    ? "Unavailable"
                    : "${temperature.toString()}°C",
              ),

              const SizedBox(height: 11),

              _StatusRow(
                Icons.water_drop_outlined,
                Colors.indigo,
                'Rainfall now',
                precipitation == null
                    ? "Unavailable"
                    : "${precipitation.toString()} mm",
              ),

              const SizedBox(height: 11),
    
    
            

              
            ],
          ],
        ),
      ),
    );
  }
}

class _BroadcastAlertsCard extends StatelessWidget {
  const _BroadcastAlertsCard();

  Future<void> _openGoogleMaps(
  BuildContext context,
  double? latitude,
  double? longitude,
) async {
  if (latitude == null || longitude == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exact location is unavailable for this alert'),
      ),
    );
    return;
  }

  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
  );

  try {
  final opened = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Maps is not installed or cannot be opened'),
      ),
    );
  }
} catch (e) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open Google Maps'),
      ),
    );
  }
}
}

  void _showAlertDetails(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final latitude = (data['latitude'] as num?)?.toDouble();
    final longitude = (data['longitude'] as num?)?.toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['title']?.toString() ?? 'Emergency Alert',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data['message']?.toString() ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'Priority: ${data['priority']?.toString() ?? 'High'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 18),
if (latitude != null && longitude != null)
  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      icon: const Icon(Icons.map),
      label: const Text('Open location in Google Maps'),
      onPressed: () {
        _openGoogleMaps(context, latitude, longitude);
      },
    ),
  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
    .collection('broadcast_alerts')
    .where('status', isEqualTo: 'Active')
    .limit(5)
    .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final alerts = [...(snapshot.data?.docs ?? [])];

alerts.sort((a, b) {
  final priorityOrder = {
    'High': 0,
    'Medium': 1,
    'Low': 2,
  };

  final aData = a.data() as Map<String, dynamic>;
  final bData = b.data() as Map<String, dynamic>;

  final aPriority = aData['priority']?.toString() ?? 'Low';
  final bPriority = bData['priority']?.toString() ?? 'Low';

  return (priorityOrder[aPriority] ?? 3)
      .compareTo(priorityOrder[bPriority] ?? 3);
});

        if (alerts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Emergency Broadcasts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...alerts.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final latitude = (data['latitude'] as num?)?.toDouble();
final longitude = (data['longitude'] as num?)?.toDouble();

                  final priority =
                      data['priority']?.toString() ?? 'High';

                  final priorityColor = priority == 'High'
                      ? Colors.red
                      : priority == 'Medium'
                          ? Colors.orange
                          : Colors.green;

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showAlertDetails(context, data),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.08),
                        border: Border.all(
                          color: priorityColor.withValues(alpha: 0.35),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['title']?.toString() ??
                                      'Emergency Alert',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(
                                priority,
                                style: TextStyle(
                                  color: priorityColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data['message']?.toString() ?? '',
                          ),
                          const SizedBox(height: 6),
                          if (latitude != null && longitude != null)
  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      icon: const Icon(Icons.map),
      label: const Text('Open location in Google Maps'),
      onPressed: () {
        _openGoogleMaps(
          context,
          latitude,
          longitude,
        );
      },
    ),
  ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow(this.icon, this.color, this.label, this.value);
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SosButton extends StatelessWidget {
  const _SosButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 164,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.sos, size: 42),
        label: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('EMERGENCY SOS', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text('Tap for immediate help'),
          ],
        ),
      ),
    );
  }
}

class _DashboardItem extends StatelessWidget {
  const _DashboardItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 42, color: color),
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
