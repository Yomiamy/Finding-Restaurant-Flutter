import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_restaruant/firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Handling a background message ${message.messageId}");
}

class FcmManager {
  static const FCM_NOTIFICATION_CHANNEL_ID = "fcm_notification_channel_id";
  static const FCM_NOTIFICATION_CHANNEL_NAME = "fcm_notification_channel_name";
  static const FCM_NOTIFICATION_CHANNEL_DESCRIPTION =
      "Android Notification Channel";
  static final FcmManager _singleton = FcmManager._internal();

  FcmManager._internal();

  factory FcmManager() => _singleton;

  Future<String> get fcmToken async =>
      await FirebaseMessaging.instance.getToken() ?? "";
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void _firebaseMessagingOpenHandler(RemoteMessage message) async {
    print("Handling a message open: ${message.messageId}");
  }

  void _firebaseMessagingForgroundHandler(RemoteMessage message) {
    print("Handling a foreground message: ${message.messageId}");

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      // Android app 前景顯示通知
      _flutterLocalNotificationsPlugin.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  FCM_NOTIFICATION_CHANNEL_ID,
                  FCM_NOTIFICATION_CHANNEL_NAME,
                  channelDescription: FCM_NOTIFICATION_CHANNEL_DESCRIPTION,
                  icon: android.smallIcon,
                  importance: Importance.max,
                  priority: Priority.high,
                  // other properties...
                ),
              ))
          .onError((error, stackTrace) =>
              {
                print("Handling a foreground message error: $error")
              });
    }
  }

  void init() async {
    if (Platform.isIOS) {
      // For iOS foreground notification
      FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true, badge: true, sound: true);
    }

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_firebaseMessagingForgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(_firebaseMessagingOpenHandler);
  }

  void requestPermission() async {
    try {
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      print('User granted permission: ${settings.authorizationStatus}');
    } on Exception catch (_) {
      print('FCM request fail');
    }
  }
}
