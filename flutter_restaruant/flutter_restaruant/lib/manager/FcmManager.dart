import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_restaruant/firebase_options.dart';
import 'package:flutter_restaruant/flow/main/view/MainPage.dart';
import 'package:flutter_restaruant/flow/splash/view/SplashPage.dart';
import 'package:flutter_restaruant/main.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Handling a background message ${message.messageId}");
}

class FcmManager {

  static final FcmManager _singleton = FcmManager._internal();

  FcmManager._internal();

  factory FcmManager() => _singleton;

  Future<String> get fcmToken async => await FirebaseMessaging.instance.getToken() ?? "";
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  void _firebaseMessagingOpenHandler(RemoteMessage message) async {
    print("Handling a message open: ${message.messageId}");

    final BuildContext? context = navigatorKey.currentContext;

    if(context == null) {
      return;
    }

    YelpRestaurantSummaryInfo summaryInfo = (){
      String storeId = message.data[Constants.FCM_NOTIFICATION_PAYLOAD_KEY_STORE_ID];
      YelpRestaurantSummaryInfo summaryInfo = YelpRestaurantSummaryInfo();

      summaryInfo.id = storeId;
      return summaryInfo;
    }();
    Tuple2 arguments = Tuple2<YelpRestaurantSummaryInfo, dynamic>(summaryInfo, null);
    Navigator.of(context).pushNamedAndRemoveUntil(MainPage.ROUTE_NAME, ModalRoute.withName(SplashPage.ROUTE_NAME), arguments: arguments);
  }

  void _firebaseForegroundMessagingOpenHandler(NotificationResponse? notificationResponse) async {
    String? payload = notificationResponse?.payload;

    print("Handling a message open: ${payload}");

    if(payload == null || payload.isEmpty) {
      return;
    }

    Map<String, dynamic> data = JsonDecoder().convert(payload) as Map<String, dynamic>;
    RemoteMessage message = RemoteMessage(data: data);
    _firebaseMessagingOpenHandler(message);
  }

  void _firebaseMessagingForegroundHandler(RemoteMessage message) {
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
                  Constants.FCM_NOTIFICATION_CHANNEL_ID,
                  Constants.FCM_NOTIFICATION_CHANNEL_NAME,
                  channelDescription: Constants.FCM_NOTIFICATION_CHANNEL_DESCRIPTION,
                  icon: android.smallIcon,
                  importance: Importance.max,
                  priority: Priority.high,
                  // other properties...
                ),
              ),
              payload: JsonEncoder().convert(message.data))
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

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(UIConstants.FCM_NOTIFICATION_ICON);
    const DarwinInitializationSettings initializationSettingsIos = DarwinInitializationSettings();
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIos);
    _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _firebaseForegroundMessagingOpenHandler
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_firebaseMessagingForegroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(_firebaseMessagingOpenHandler);
    FirebaseMessaging.instance.getInitialMessage().then((message) {
        print("Handling a init message: $message");
        if(message == null) {
          return;
        }

        Future.delayed(Duration(seconds: 8), () {
          _firebaseMessagingOpenHandler(message);
        });
    });
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
