import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

class PersonDetection {
  final Rect box;
  final double confidence;

  const PersonDetection({
    required this.box,
    required this.confidence,
  });
}

class CctvPersonDetector {
  YOLO? _yolo;
  bool _loaded = false;

  Future<void> initialize() async {
    if (_loaded) return;

    final modelId =
        YOLO.defaultOfficialModel() ?? 'yolo26n';

    _yolo = YOLO(
      modelPath: modelId,
      task: YOLOTask.detect,
      useGpu: true,
    );

    final loaded = await _yolo!.loadModel();

    if (!loaded) {
      throw Exception(
        'Unable to load YOLO model.',
      );
    }

    _loaded = true;

    debugPrint('YOLO MODEL LOADED: $modelId');
  }

  Future<List<PersonDetection>> detectPeople(
    Uint8List imageBytes,
  ) async {
    if (!_loaded || _yolo == null) {
      await initialize();
    }

    final resultMap = await _yolo!.predict(
      imageBytes,
      confidenceThreshold: 0.45,
      iouThreshold: 0.5,
    );

    final result =
        YOLODetectionResults.fromMap(resultMap);

    final detections =
        <PersonDetection>[];

    for (final detection
        in result.detections) {
      if (detection.className.toLowerCase() !=
          'person') {
        continue;
      }

      if (detection.confidence < 0.45) {
        continue;
      }

      detections.add(
        PersonDetection(
          box: detection.normalizedBox,
          confidence: detection.confidence,
        ),
      );
    }

    debugPrint(
      'YOLO PERSONS DETECTED: ${detections.length}',
    );

    return detections;
  }

  Future<void> dispose() async {
    await _yolo?.dispose();

    _yolo = null;
    _loaded = false;
  }
}