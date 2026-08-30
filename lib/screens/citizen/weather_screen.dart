import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/ai_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final AIService _aiService = AIService();

  Map<String, dynamic>? _weather;
  bool _loading = true;
  bool _refreshing = false;
  String _error = '';
  DateTime? _lastUpdated;
  double? _latitude;
double? _longitude;
String? _locationName;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
  final isFirstLoad = _weather == null;

  setState(() {
    if (isFirstLoad) {
      _loading = true;
    } else {
      _refreshing = true;
    }
    _error = '';
  });

  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    final weather = await _aiService.getWeatherEvidence(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (!mounted) return;

await _getLocationName(
  position.latitude,
  position.longitude,
);

if (!mounted) return;

setState(() {
  _weather = weather;
  _latitude = position.latitude;
  _longitude = position.longitude;
  _lastUpdated = DateTime.now();
  _loading = false;
  _refreshing = false;
});
  } catch (e) {
  if (!mounted) return;

  setState(() {
    _loading = false;
    _refreshing = false;

    if (isFirstLoad) {
      _error =
          'Unable to load live weather. Please check location and internet.';
    }
  });

  if (!isFirstLoad && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to refresh weather. Showing the last available report.',
        ),
      ),
    );
  }
}
}
Future<void> _getLocationName(
  double latitude,
  double longitude,
) async {
  try {
    final placemarks = await placemarkFromCoordinates(
      latitude,
      longitude,
    );

    if (placemarks.isNotEmpty && mounted) {
      final place = placemarks.first;

      final parts = <String>[
        if (place.locality != null &&
            place.locality!.isNotEmpty)
          place.locality!,

        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty)
          place.administrativeArea!,
      ];

      setState(() {
        _locationName = parts.isNotEmpty
            ? parts.join(', ')
            : null;
      });
    }
  } catch (_) {
    // GPS coordinates will still be shown if place lookup fails.
  }
}

  String _weatherDescription(dynamic code) {
    if (code == null) return 'Unavailable';

    final value = (code as num).toInt();

    if (value == 0) return 'Clear';
    if (value <= 3) return 'Partly cloudy';
    if (value <= 48) return 'Fog';
    if (value <= 57) return 'Drizzle';
    if (value <= 67) return 'Rain';
    if (value <= 77) return 'Snow';
    if (value <= 82) return 'Rain showers';
    if (value <= 86) return 'Snow showers';
    if (value >= 95) return 'Thunderstorm';

    return 'Changing conditions';
  }

  String _riskLevel() {
  final floodRisk = _floodRisk();
  final windRisk = _windRisk();

  final thunderstormHours =
      (_weather?['thunderstormHoursNext24'] as num?)?.toInt() ?? 0;

  if (floodRisk == 'High' ||
      windRisk == 'High' ||
      thunderstormHours >= 3) {
    return 'High';
  }

  if (floodRisk == 'Moderate' ||
      windRisk == 'Moderate' ||
      thunderstormHours > 0) {
    return 'Moderate';
  }

  return 'Low';
}

  String _floodRisk() {
  final rainLast24 =
      (_weather?['rainfallLast24Hours'] as num?)?.toDouble() ?? 0;

  final rainNext24 =
      (_weather?['rainfallNext24Hours'] as num?)?.toDouble() ?? 0;

  final rainProbability =
      (_weather?['tomorrowRainProbability'] as num?)?.toDouble() ?? 0;

  final totalRainRisk = rainLast24 + rainNext24;

  if (totalRainRisk >= 150 ||
      (rainLast24 >= 100 && rainNext24 >= 50)) {
    return 'High';
  }

  if (totalRainRisk >= 60 ||
      (rainNext24 >= 40 && rainProbability >= 70)) {
    return 'Moderate';
  }

  return 'Low';
}

  String _windRisk() {
  final currentWind =
      (_weather?['windSpeed'] as num?)?.toDouble() ?? 0;

  final maxWind =
      (_weather?['maxWindNext24Hours'] as num?)?.toDouble() ?? 0;

  final maxGust =
      (_weather?['maxWindGustNext24Hours'] as num?)?.toDouble() ?? 0;

  final strongestWind =
      [currentWind, maxWind, maxGust].reduce(
    (a, b) => a > b ? a : b,
  );

  if (strongestWind >= 70) return 'High';
  if (strongestWind >= 45) return 'Moderate';

  return 'Low';
}
String _weatherAlertMessage() {
  final floodRisk = _floodRisk();
  final windRisk = _windRisk();

  final thunderstormHours =
      (_weather?['thunderstormHoursNext24'] as num?)?.toInt() ?? 0;

  if (floodRisk == 'High') {
    return 'Heavy rainfall conditions may increase flood risk. Avoid low-lying areas and follow official emergency warnings.';
  }

  if (windRisk == 'High') {
    return 'Strong winds are forecast. Avoid exposed areas and secure loose outdoor objects.';
  }

  if (thunderstormHours > 0) {
    return 'Thunderstorm conditions are expected. Avoid open areas and stay updated with official weather warnings.';
  }

  if (_riskLevel() == 'Moderate') {
    return 'Weather conditions may worsen. Stay alert and monitor local emergency updates.';
  }

  return '';
}

    Color _riskColor(String risk) {
    switch (risk) {
      case 'High':
        return Colors.red;
      case 'Moderate':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _formatLastUpdated(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final temperature = _weather?['temperature'];
final humidity = _weather?['humidity'];
final precipitation = _weather?['precipitation'];
final wind = _weather?['windSpeed'];
final weatherCode = _weather?['weatherCode'];

final tomorrowWeatherCode = _weather?['tomorrowWeatherCode'];
final tomorrowMaxTemp = _weather?['tomorrowMaxTemp'];
final tomorrowMinTemp = _weather?['tomorrowMinTemp'];
final tomorrowRainProbability =
    _weather?['tomorrowRainProbability'];

    final weatherText = _weatherDescription(weatherCode);
    final floodRisk = _floodRisk();
    final windRisk = _windRisk();
    final overallRisk = _riskLevel();
    final weatherAlert = _weatherAlertMessage();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
  title: const Text('Weather & Risk'),
  backgroundColor: const Color(0xFF0B3D91),
  foregroundColor: Colors.white,
  actions: [
    IconButton(
  tooltip: 'Refresh weather',
  onPressed: _refreshing ? null : _loadWeather,
  icon: _refreshing
      ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        )
      : const Icon(Icons.refresh),
),
  ],
),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadWeather,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
    onRefresh: _loadWeather,
    child: ListView(
      padding: const EdgeInsets.all(18),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (weatherAlert.isNotEmpty) ...[
  _WeatherAlertBanner(
    message: weatherAlert,
    risk: overallRisk,
  ),
  const SizedBox(height: 14),
],
                    _CurrentWeatherCard(
  weather: weatherText,
  temperature: temperature,
  humidity: humidity,
),

const SizedBox(height: 8),

if (_lastUpdated != null)
  Center(
    child: Text(
      'Last updated: ${_formatLastUpdated(_lastUpdated!)}',
      style: const TextStyle(
        color: Colors.black54,
        fontSize: 12,
      ),
    ),
  ),

const SizedBox(height: 6),

if (_latitude != null && _longitude != null)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 10,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF4FA),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 20,
          color: Color(0xFF0B3D91),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _locationName ?? 'Current GPS location',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'GPS-based location',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Live weather report • Updated '
                '${_lastUpdated != null ? _formatLastUpdated(_lastUpdated!) : 'recently'}',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),

const SizedBox(height: 18),

_WeatherInfoCard(
  temperature: temperature,
  humidity: humidity,
  precipitation: precipitation,
  wind: wind,
),

const SizedBox(height: 22),

const Text(
  'Tomorrow Forecast',
  style: TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 12),

_TomorrowForecastCard(
  weather: _weatherDescription(tomorrowWeatherCode),
  maxTemp: tomorrowMaxTemp,
  minTemp: tomorrowMinTemp,
  rainProbability: tomorrowRainProbability,
),

const SizedBox(height: 22),

const Text(
  'Safety assessment',
  style: TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.bold,
  ),
),

                    const SizedBox(height: 12),

                    _RiskCard(
  icon: Icons.water_drop_outlined,
  title: 'Flood risk',
  value: floodRisk,
  detail:
      'Past 24h: ${((_weather?['rainfallLast24Hours'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} mm • '
      'Next 24h: ${((_weather?['rainfallNext24Hours'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} mm',
  color: _riskColor(floodRisk),
),

                    const SizedBox(height: 12),

                    _RiskCard(
  icon: Icons.air_outlined,
  title: 'Wind risk',
  value: windRisk,
  detail:
      'Current: ${((_weather?['windSpeed'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} km/h • '
      'Max forecast gust: ${((_weather?['maxWindGustNext24Hours'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} km/h',
  color: _riskColor(windRisk),
),

                    const SizedBox(height: 12),

                    _RiskCard(
  icon: Icons.warning_amber_outlined,
  title: 'Overall weather risk',
  value: overallRisk,
  detail:
      'Forecast rain: ${((_weather?['rainfallNext24Hours'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} mm • '
      'Thunderstorm hours: ${(_weather?['thunderstormHoursNext24'] ?? 0)}',
  color: _riskColor(overallRisk),
),

const SizedBox(height: 16),

_SafetyRecommendationCard(
  risk: overallRisk,
),

const SizedBox(height: 20),

const Text(
  'Weather data is based on the current device location and available weather service data. Risk values are automated indicators and should not replace official emergency warnings.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                 ),
                 
    );
  }
}
class _SafetyRecommendationCard extends StatelessWidget {
  const _SafetyRecommendationCard({
    required this.risk,
  });

  final String risk;

  @override
  Widget build(BuildContext context) {
    String title;
    String message;
    IconData icon;
    Color color;

    switch (risk) {
      case 'High':
        title = 'Safety recommendation';
        message =
            'Avoid unnecessary travel and vulnerable areas. Stay updated with official weather and emergency warnings.';
        icon = Icons.warning_amber_rounded;
        color = Colors.red;
        break;

      case 'Moderate':
        title = 'Stay alert';
        message =
            'Weather conditions may worsen. Monitor updates and avoid low-lying or exposed areas if conditions change.';
        icon = Icons.visibility_outlined;
        color = Colors.orange;
        break;

      default:
        title = 'Current recommendation';
        message =
            'No major weather risk is currently indicated. Continue monitoring weather updates.';
        icon = Icons.check_circle_outline;
        color = Colors.green;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 30,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherAlertBanner extends StatelessWidget {
  const _WeatherAlertBanner({
    required this.message,
    required this.risk,
  });

  final String message;
  final String risk;

  @override
  Widget build(BuildContext context) {
    final isHigh = risk == 'High';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHigh
            ? Colors.red.withValues(alpha: 0.10)
            : Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHigh ? Colors.red : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: isHigh ? Colors.red : Colors.orange,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHigh ? 'WEATHER ALERT' : 'WEATHER ADVISORY',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isHigh ? Colors.red : Colors.orange,
                  ),
                ),
                const SizedBox(height: 5),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentWeatherCard extends StatelessWidget {
  const _CurrentWeatherCard({
    required this.weather,
    required this.temperature,
    required this.humidity,
  });

  final String weather;
  final dynamic temperature;
  final dynamic humidity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1976D2),
            Color(0xFF64B5F6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${temperature ?? "—"}°C · Humidity ${humidity ?? "—"}%',
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Live weather status',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherInfoCard extends StatelessWidget {
  const _WeatherInfoCard({
    required this.temperature,
    required this.humidity,
    required this.precipitation,
    required this.wind,
  });

  final dynamic temperature;
  final dynamic humidity;
  final dynamic precipitation;
  final dynamic wind;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _WeatherRow(
              Icons.thermostat,
              'Temperature',
              '${temperature ?? "—"}°C',
            ),
            const Divider(),
            _WeatherRow(
              Icons.water_drop_outlined,
              'Humidity',
              '${humidity ?? "—"}%',
            ),
            const Divider(),
            _WeatherRow(
              Icons.cloudy_snowing,
              'Precipitation',
              '${precipitation ?? "—"} mm',
            ),
            const Divider(),
            _WeatherRow(
              Icons.air,
              'Wind speed',
              '${wind ?? "—"} km/h',
            ),
          ],
        ),
      ),
    );
  }
}
class _TomorrowForecastCard extends StatelessWidget {
  const _TomorrowForecastCard({
    required this.weather,
    required this.maxTemp,
    required this.minTemp,
    required this.rainProbability,
  });

  final String weather;
  final dynamic maxTemp;
  final dynamic minTemp;
  final dynamic rainProbability;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF0B3D91),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Tomorrow',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  weather,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ForecastValue(
                  icon: Icons.arrow_upward,
                  label: 'Max',
                  value: '${maxTemp ?? "—"}°C',
                ),

                _ForecastValue(
                  icon: Icons.arrow_downward,
                  label: 'Min',
                  value: '${minTemp ?? "—"}°C',
                ),

                _ForecastValue(
                  icon: Icons.water_drop_outlined,
                  label: 'Rain',
                  value: '${rainProbability ?? "—"}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastValue extends StatelessWidget {
  const _ForecastValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF0B3D91),
        ),
        const SizedBox(height: 6),
        Text(label),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
class _WeatherRow extends StatelessWidget {
  const _WeatherRow(
    this.icon,
    this.label,
    this.value,
  );

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0B3D91)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.13),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(detail),
        trailing: Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}