import 'package:flutter/material.dart';

class LearningHubScreen extends StatelessWidget {
  const LearningHubScreen({super.key});

  static const _lessons = <_Lesson>[
    _Lesson(Icons.water_drop_outlined, Colors.indigo, 'Flood safety', 'Move to higher ground; never walk or drive through floodwater.'),
    _Lesson(Icons.local_fire_department_outlined, Colors.red, 'Fire safety', 'Leave immediately, stay low under smoke, and call emergency services.'),
    _Lesson(Icons.vibration_outlined, Colors.orange, 'Earthquake safety', 'Drop, cover, and hold on until the shaking stops.'),
    _Lesson(Icons.air_outlined, Colors.teal, 'Cyclone readiness', 'Keep a charged phone, water, medicines, and official alerts nearby.'),
  ];

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
        children: [
          const Text('Prepare before an emergency', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Short safety guidance for common disasters.'),
          const SizedBox(height: 18),
          ..._lessons.map((lesson) => _LessonCard(lesson: lesson)),
        ],
      ),
    );
  }
}

class _Lesson {
  const _Lesson(this.icon, this.color, this.title, this.tip);
  final IconData icon;
  final Color color;
  final String title;
  final String tip;
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson});
  final _Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 13),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: lesson.color.withValues(alpha: 0.14),
          child: Icon(lesson.icon, color: lesson.color),
        ),
        title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(lesson.tip),
        ),
      ),
    );
  }
}
