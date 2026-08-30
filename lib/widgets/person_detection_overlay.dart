import 'package:flutter/material.dart';

import '../services/cctv_person_detector.dart';

class PersonDetectionOverlay extends StatelessWidget {
  final List<PersonDetection> detections;

  const PersonDetectionOverlay({
    super.key,
    required this.detections,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _PersonDetectionPainter(
          detections,
        ),
      ),
    );
  }
}

class _PersonDetectionPainter
    extends CustomPainter {
  final List<PersonDetection> detections;

  _PersonDetectionPainter(
    this.detections,
  );

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final detection in detections) {
      final box = detection.box;

      final rect = Rect.fromLTWH(
        box.left * size.width,
        box.top * size.height,
        box.width * size.width,
        box.height * size.height,
      );

      canvas.drawRect(
        rect,
        paint,
      );

      final percentage =
          (detection.confidence * 100)
              .toStringAsFixed(0);

      textPaint.text = TextSpan(
        text: 'PERSON $percentage%',
        style: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white,
        ),
      );

      textPaint.layout();

      final labelOffset = Offset(
        rect.left,
        rect.top > 18
            ? rect.top - 18
            : rect.top,
      );

      textPaint.paint(
        canvas,
        labelOffset,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _PersonDetectionPainter oldDelegate,
  ) {
    return true;
  }
}