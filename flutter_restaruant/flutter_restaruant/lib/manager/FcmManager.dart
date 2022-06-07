import 'package:firebase_messaging/firebase_messaging.dart';

void _firebaseMessagingOpenHandler(RemoteMessage message) async {
  print("Handling a message open: ${message.messageId}");
}

void _firebaseMessagingForgroundHandler(RemoteMessage message) {
  print("Handling a foreground message: ${message.messageId}");
}

// TODO: 前景Notification顯示
// https://github.com/tpps89305/flutter_playground/commits/master
// https://stackoverflow.com/questions/70106773/flutter-firebase-foreground-push-notification-not-showing-but-background-is-work
class FcmManager {

  static final FcmManager _singleton = FcmManager._internal();

  FcmManager._internal();

  factory FcmManager() => _singleton;

  void init() {
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true ,sound: true);
    FirebaseMessaging.onMessage.listen(_firebaseMessagingForgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(_firebaseMessagingOpenHandler);
  }
}