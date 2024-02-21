import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:clientflow/main.dart';
import 'package:clientflow/notification_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:permission_handler/permission_handler.dart'; // For requesting permissions

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );
  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    // Check and request notification permission
    await _checkNotificationPermission();

    final fCMToken = await _firebaseMessaging.getToken();
    developer.log('FCM Token: $fCMToken');

    await initPushNotifications();
    await initLocalNotifications();
  }

  // Function to check and request notification permission
  Future<void> _checkNotificationPermission() async {
    // Check if notification permission is already granted
    if (!await Permission.notification.isGranted) {
      // Request permission if not granted
      PermissionStatus status = await Permission.notification.request();

      if (status.isGranted) {
        developer.log('Notification permission granted');
      } else {
        developer.log('Notification permission denied');
      }
    }
  }

  Future<void> initPushNotifications() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      // Show local notification if permission is granted
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@drawable/clientflow',
          ),
        ),
        payload: jsonEncode(message.toMap()),
      );

      // Display a dialog box to allow the user to choose to view the notification
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (_) => AlertDialog(
          title: Text(notification.title ?? 'New Notification'),
          content: Text(notification.body ?? ''),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(navigatorKey.currentContext!).pop(),
            ),
            TextButton(
              child: const Text('View'),
              onPressed: () {
                Navigator.of(navigatorKey.currentContext!).pop();
                handleMessage(message);
              },
            ),
          ],
        ),
      );
    });
  }

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    developer.log("Handling message: ${message.messageId}");

    // Use Future.delayed to ensure a valid navigation context
    Future.delayed(Duration.zero, () {
      developer.log("Attempting to navigate to NotificationsPage");
      navigatorKey.currentState?.pushNamed(
        NotificationsPage.route,
        arguments: message,
      );
    });
  }

  Future<void> initLocalNotifications() async {
    const iOS = IOSInitializationSettings();
    const android = AndroidInitializationSettings('@drawable/clientflow');
    const settings = InitializationSettings(android: android, iOS: iOS);

    await _localNotifications.initialize(
      settings,
      onSelectNotification: (payload) {
        developer.log("Local notification selected: $payload");
        if (payload != null) {
          final data = jsonDecode(payload);
          handleMessage(RemoteMessage(
            notification: RemoteNotification(
              title: data['title'],
              body: data['body'],
            ),
            data: data,
          ));
        }
      },
    );

    final platform = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(_androidChannel);
  }

  Future<void> sendPushNotification(String salesmanId, String title, String body) async {
    // Get FCM token
    final fcmToken = await _getFCMTokenForSalesman(salesmanId);
    developer.log('Sending push notification to token: $fcmToken');

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=AIzaSyCScCknaXQpG_apftYmhGtODr_a11YgtoY', // Firebase server key
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': body,
            'title': title,
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'done'
          },
          'to': fcmToken,
        },
      ),
    );

    if (response.statusCode == 200) {
      developer.log("Push notification sent successfully");
    } else {
      developer.log("Error sending push notification: ${response.body}");
    }
  }

  // Function to get FCM token
  Future<String> _getFCMTokenForSalesman(String salesmanId) async {
    // Replace with actual logic to fetch FCM token for the salesman
    return "salesmanFCMToken";
  }

  Future<void> showLocalNotification(String title, String body) async {
    await _localNotifications.show(
      0,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/clientflow',
        ),
      ),
      payload: jsonEncode({
        'title': title,
        'body': body,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      }),
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log("Handling a background message: ${message.messageId}");
  // Process the message here if needed
}
