import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'offline_storage_service.dart';

class SyncService {
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _isSyncing = false;

  static void start() {
    _subscription?.cancel();

    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((results) async {
      final hasInternetConnection =
          results.any((result) => result != ConnectivityResult.none);

      if (hasInternetConnection) {
        await syncPendingData();
      }
    });

    // Try syncing when the app starts.
    syncPendingData();
  }

  static Future<void> syncPendingData() async {
    if (_isSyncing) return;

    _isSyncing = true;

    try {
      final items = await OfflineStorageService.getPendingItems();

      for (int i = items.length - 1; i >= 0; i--) {
        final item = items[i];

        try {
          await _uploadItem(item);

          await OfflineStorageService.removeAt(i);
        } catch (e) {
          // Keep the item locally if upload fails.
          print('Offline sync failed: $e');
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  static Future<void> _uploadItem(
    Map<String, dynamic> item,
  ) async {
    final type = item['type'] as String?;
    final data = Map<String, dynamic>.from(item['data'] ?? {});

    if (type == null || type.isEmpty) {
      throw Exception('Invalid offline item type');
    }

    final collection = _collectionForType(type);

    await FirebaseFirestore.instance
        .collection(collection)
        .add({
      ...data,
      'syncedFromOffline': true,
      'syncedAt': FieldValue.serverTimestamp(),
    });
  }

  static String _collectionForType(String type) {
    switch (type) {
      case 'emergency':
        return 'reports';

      case 'report':
        return 'reports';

      case 'alert':
        return 'notifications';

      default:
        throw Exception('Unknown offline data type: $type');
    }
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}