import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Android local notification setup
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
  settings: initializationSettings,
);

    // Firebase notification permission
    NotificationSettings settings =
        await _messaging.requestPermission();

    print('Permission: ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await _messaging.getToken();

    print('FCM TOKEN GENERATED');

    // Save token for logged-in user
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      print('FCM token saved to Firestore');
    }

    // Firebase message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notification Received');

      _showLocalNotification(
        title: message.notification?.title ?? 'AEGIS AI',
        body: message.notification?.body ?? 'New notification',
      );
    });
  }

  Future<void> showSosNotification({
    required String citizenName,
    required String location,
  }) async {
    await _showLocalNotification(
      title: '🚨 NEW EMERGENCY SOS',
      body: '$citizenName needs help near $location',
    );
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'emergency_sos_channel',
      'Emergency SOS Alerts',
      channelDescription: 'Urgent emergency SOS notifications',
      importance: Importance.max,
      priority: Priority.high,
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