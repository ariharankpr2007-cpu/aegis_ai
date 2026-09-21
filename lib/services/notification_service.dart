import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // --------------------------------------------------
    // 1. LOCAL NOTIFICATION SETUP
    // Works without internet.
    // --------------------------------------------------

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
    );

    // Android 13+ notification permission
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();

    // --------------------------------------------------
    // 2. FIREBASE SERVICES
    // These are optional and may fail offline.
    // --------------------------------------------------

    try {
      NotificationSettings settings =
          await _messaging.requestPermission();

      print(
        'Permission: ${settings.authorizationStatus}',
      );

      String? token = await _messaging.getToken();

      if (token != null) {
        print('FCM TOKEN GENERATED');

        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(
            {
              'fcmToken': token,
              'fcmTokenUpdatedAt':
                  FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          print('FCM token saved to Firestore');
        }
      }
    } catch (e) {
      print(
        'FCM unavailable - AEGIS running offline: $e',
      );
    }

    // --------------------------------------------------
    // 3. FOREGROUND FCM LISTENER
    // --------------------------------------------------

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        print('Notification Received');

        _showLocalNotification(
          title: message.notification?.title ??
              'AEGIS AI',
          body: message.notification?.body ??
              'New notification',
        );
      },
    );
  }

  // --------------------------------------------------
  // OFFLINE EMERGENCY NOTIFICATION
  // --------------------------------------------------

  Future<void> showOfflineEmergencyNotification({
    required String title,
    required String body,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
    );
  }

  // --------------------------------------------------
  // EXISTING SOS NOTIFICATION
  // --------------------------------------------------

  Future<void> showSosNotification({
    required String citizenName,
    required String location,
  }) async {
    await _showLocalNotification(
      title: '🚨 NEW EMERGENCY SOS',
      body:
          '$citizenName needs help near $location',
    );
  }

  // --------------------------------------------------
  // LOCAL NOTIFICATION
  // --------------------------------------------------

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'emergency_sos_channel',
      'Emergency SOS Alerts',
      channelDescription:
          'Urgent emergency SOS notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details =
        NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}