import 'package:flutter/material.dart';

class LearningHubScreen extends StatelessWidget {
  const LearningHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Learning Hub'),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          Text(
            'Prepare Before an Emergency',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Learn what to do before, during, and after common disasters.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),

          _LessonCard(
            icon: Icons.water_drop_outlined,
            color: Colors.indigo,
            title: 'Flood Safety',
            description:
                'Learn how to stay safe during flooding.',
            details: [
              'Move to higher ground.',
              'Never walk through moving floodwater.',
              'Never drive through flooded roads.',
              'Follow official evacuation instructions.',
              'Keep your phone charged.',
            ],
          ),

          _LessonCard(
            icon: Icons.local_fire_department_outlined,
            color: Colors.red,
            title: 'Fire Safety',
            description:
                'Learn what to do when a fire occurs.',
            details: [
              'Raise the alarm immediately.',
              'Leave the building safely.',
              'Stay low under smoke.',
              'Do not use elevators.',
              'Never go back into a burning building.',
            ],
          ),

          _LessonCard(
            icon: Icons.vibration_outlined,
            color: Colors.orange,
            title: 'Earthquake Safety',
            description:
                'Learn how to protect yourself during an earthquake.',
            details: [
              'Drop to the ground.',
              'Take cover under sturdy furniture.',
              'Hold on until the shaking stops.',
              'Stay away from windows.',
              'Expect possible aftershocks.',
            ],
          ),

          _LessonCard(
            icon: Icons.air_outlined,
            color: Colors.teal,
            title: 'Cyclone Readiness',
            description:
                'Prepare yourself and your home for cyclones.',
            details: [
              'Monitor official weather warnings.',
              'Charge your phone and power bank.',
              'Store drinking water.',
              'Keep medicines ready.',
              'Stay indoors during dangerous conditions.',
            ],
          ),

          _LessonCard(
            icon: Icons.landslide_outlined,
            color: Colors.brown,
            title: 'Landslide Safety',
            description:
                'Learn how to respond to landslide warnings.',
            details: [
              'Move away from unstable slopes.',
              'Follow evacuation instructions.',
              'Avoid valleys and low-lying areas.',
              'Watch for cracks in the ground.',
              'Do not return until authorities say it is safe.',
            ],
          ),

          _LessonCard(
            icon: Icons.waves_outlined,
            color: Colors.blue,
            title: 'Tsunami Safety',
            description:
                'Learn how to respond to tsunami warnings.',
            details: [
              'Move to higher ground immediately.',
              'Move inland away from the coast.',
              'Follow evacuation signs.',
              'Never wait to see the wave.',
              'Stay away until authorities give the all-clear.',
            ],
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.details,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final List<String> details;

  void _showLesson(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(
                      icon,
                      color: color,
                      size: 55,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: Text(
                      description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Safety Guidelines',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ...details.map(
                    (detail) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: color,
                            size: 21,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              detail,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('DONE'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => _showLesson(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor:
                    color.withValues(alpha: 0.14),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(description),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.arrow_forward_ios,
                size: 17,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}