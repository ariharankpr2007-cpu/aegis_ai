import 'package:hive_flutter/hive_flutter.dart';

class OfflineStorageService {
  static const String _boxName = 'offline_queue';

  static Box? _offlineBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isBoxOpen(_boxName)) {
      _offlineBox = await Hive.openBox(_boxName);
    } else {
      _offlineBox = Hive.box(_boxName);
    }
  }

  static Future<Box> _getBox() async {
    if (_offlineBox != null && _offlineBox!.isOpen) {
      return _offlineBox!;
    }

    // Automatically initialize if main() hasn't done it yet.
    await init();

    if (_offlineBox == null || !_offlineBox!.isOpen) {
      throw Exception('Could not open offline storage box.');
    }

    return _offlineBox!;
  }

  static Future<void> addToQueue({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final box = await _getBox();

    await box.add({
      'type': type,
      'data': data,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingItems() async {
    final box = await _getBox();

    return box.values
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<void> removeAt(int index) async {
    final box = await _getBox();
    await box.deleteAt(index);
  }

  static Future<int> get pendingCount async {
    final box = await _getBox();
    return box.length;
  }

  static Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}