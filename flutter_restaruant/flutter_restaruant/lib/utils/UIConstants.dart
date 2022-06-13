import 'dart:ui';

import 'package:flutter/widgets.dart';

class UIConstants {

  /// [FCM]
  static const FCM_NOTIFICATION_ICON = "@mipmap/ic_launcher";

  /// [UI]
  static const APP_TITLE = "尋找餐廳";
  static const LOGIN_TITLE = "登入";
  static const FAVOR_TITLE = "我喜好的店家";

  static const String NO_IMAGE = "images/empty.png";
  static const double RATING_IMAGE_W = 100.0;
  static const double RATING_IMAGE_H = 20.0;
  static const double FAVOR_IMAGE_H = 20.0;
  static const double FAVOR_IMAGE_W = 20.0;

  static const APP_PRIMARY_COLOR = 0xffd84a20;
  static const BACK_BTN_COLOR = 0xffffffff;

  static const EMPTY_WIDGET = SizedBox(height: 0);

  static int InterstitialADCountDown = 3;
}