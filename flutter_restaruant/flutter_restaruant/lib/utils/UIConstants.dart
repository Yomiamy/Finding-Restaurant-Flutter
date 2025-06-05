import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  static const MAP_DEFAULT_LOCATION = LatLng(25.048036, 121.517063);
  static const MAP_MY_LOCATION_MARK_ID = "MAP_MY_LOCATION_MARK_ID";

  // AD
  static int InterstitialADCountDown = 3;

  // Dimens
  static const double xlFontSize = 10;
  static const double lFontSize = 12;
  static const double mFontSize = 14;
  static const double hFontSize = 16;
  static const double xhFontSize = 18;
  static const double xxhFontSize = 20;
  static const double xxxhFontSize = 22;
  static const double xxxxhFontSize = 24;
  static const double xxxxxhFontSize = 26;
  static const double xxxxxxhFontSize = 28;
}
