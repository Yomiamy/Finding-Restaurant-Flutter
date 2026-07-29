import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UIConstants {
  /// [FCM]
  static const fcmNotificationIcon = '@mipmap/ic_launcher';

  /// [UI]
  static const appTitle = '尋找餐廳';
  static const loginTitle = '登入';
  static const favorTitle = '我喜好的店家';

  static const String noImage = 'images/empty.png';
  static const double ratingImageW = 100.0;
  static const double ratingImageH = 20.0;
  static const double favorImageH = 20.0;
  static const double favorImageW = 20.0;

  static const emptyWidget = SizedBox(height: 0);

  static const mapDefaultLocation = LatLng(25.048036, 121.517063);
  static const mapMyLocationMarkId = 'MAP_MY_LOCATION_MARK_ID';

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
