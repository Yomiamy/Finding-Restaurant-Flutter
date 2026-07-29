import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../domain/entities/restaurant_entity.dart';
import '../firebase_options.dart';
import '../flow/main/view/main_page.dart';
import '../flow/splash/view/splash_page.dart';
import '../main.dart';
import '../utils/constants.dart';
import '../utils/tuple.dart';
import '../utils/ui_constants.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Handling a background message ${message.messageId}');
}

class FcmManager {
  static final FcmManager _singleton = FcmManager._internal();

  FcmManager._internal();

  factory FcmManager() => _singleton;

  Future<String> get fcmToken async =>
      await FirebaseMessaging.instance.getToken() ?? '';
  late final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void _firebaseMessagingOpenHandler(RemoteMessage message) async {
    debugPrint('Handling a message open: ${message.messageId}');

    String? storeId =
        message.data[Constants.fcmNotificationPayloadKeyStoreId];
    Tuple2? arguments;

    if (storeId != null && storeId.isNotEmpty) {
      RestaurantEntity summaryInfo = RestaurantEntity(id: storeId);
      arguments = Tuple2<RestaurantEntity, dynamic>(summaryInfo, null);
    }

    // Delay navigation
    Future.delayed(const Duration(seconds: 8), () {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
          MainPage.routeName, ModalRoute.withName(SplashPage.routeName),
          arguments: arguments);
    });
  }

  void _firebaseForegroundMessagingOpenHandler(
      NotificationResponse? notificationResponse) async {
    String? payload = notificationResponse?.payload;

    debugPrint('Handling a message open: $payload');

    if (payload == null || payload.isEmpty) {
      return;
    }

    Map<String, dynamic> data =
        const JsonDecoder().convert(payload) as Map<String, dynamic>;
    RemoteMessage message = RemoteMessage(data: data);
    _firebaseMessagingOpenHandler(message);
  }

  void _firebaseMessagingForegroundHandler(RemoteMessage message) {
    debugPrint('Handling a foreground message: ${message.messageId}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      // Android app 前判顯示通知
      _flutterLocalNotificationsPlugin
          .show(
              id: notification.hashCode,
              title: notification.title,
              body: notification.body,
              notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                  Constants.fcmNotificationChannelId,
                  Constants.fcmNotificationChannelName,
                  channelDescription:
                      Constants.fcmNotificationChannelDescription,
                  icon: android.smallIcon,
                  importance: Importance.max,
                  priority: Priority.high,
                  // other properties...
                ),
              ),
              payload: const JsonEncoder().convert(message.data))
          .onError((error, stackTrace) {
        debugPrint('Handling a foreground message error: $error');
      });
    }
  }

  void init() async {
    if (Platform.isIOS) {
      // For iOS foreground notification
      // ignore: unawaited_futures
      FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true, badge: true, sound: true);
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(UIConstants.fcmNotificationIcon);
    const DarwinInitializationSettings initializationSettingsIos =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIos);

    // Foreground messages opened
    // ignore: unawaited_futures
    _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse:
            _firebaseForegroundMessagingOpenHandler);
    // Foreground messages display
    FirebaseMessaging.onMessage.listen(_firebaseMessagingForegroundHandler);

    // Background Message
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    //  A Stream which posts a RemoteMessage when the application is opened from a background state.
    FirebaseMessaging.onMessageOpenedApp.listen(_firebaseMessagingOpenHandler);

    // If the application is opened from a terminated state a Future containing a RemoteMessage will be returned.
    // Once consumed, the RemoteMessage will be returned.
    // ignore: unawaited_futures
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      debugPrint('Handling a init message: $message');
      if (message == null) {
        debugPrint('Handling a init message: message == null');
        return;
      }

      _firebaseMessagingOpenHandler(message);
    });
  }

  Future<void> requestPermission() async {
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
      debugPrint('User granted permission: ${settings.authorizationStatus}');
    } on Exception catch (e) {
      debugPrint('FCM request fail, ${e.toString()}');
    }
  }
}
