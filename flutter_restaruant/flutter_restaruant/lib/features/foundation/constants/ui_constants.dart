import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../style/style_barrel.dart';

class UIConstants {
  /// [FCM]
  static const fcmNotificationIcon = '@mipmap/ic_launcher';

  /// [UI]
  static const appTitle = '尋找餐廳';
  static const loginTitle = '登入';
  static const favorTitle = '我喜好的店家';

  static const String noImage = 'images/empty.png';

  static const emptyWidget = SizedBox(height: ThemeSize.zero);

  static const mapDefaultLocation = LatLng(25.048036, 121.517063);
  static const mapMyLocationMarkId = 'MAP_MY_LOCATION_MARK_ID';

  // Font sizes
  // ponytail: 保留不刪，29 處使用點待 S4 遷移。移除是 S4 之後的獨立 PR。
  @Deprecated('改用 Theme.of(context).textTheme（無對應角色，未被使用）')
  static const double xlFontSize = 10;
  @Deprecated('改用 Theme.of(context).textTheme.labelSmall')
  static const double lFontSize = 12;
  @Deprecated('改用 Theme.of(context).textTheme.bodyMedium')
  static const double mFontSize = 14;
  @Deprecated('改用 Theme.of(context).textTheme.bodyLarge')
  static const double hFontSize = 16;
  @Deprecated('改用 Theme.of(context).textTheme.titleMedium')
  static const double xhFontSize = 18;
  @Deprecated('改用 Theme.of(context).textTheme.titleMedium（實測僅 1 處）')
  static const double xxhFontSize = 20;
  @Deprecated('改用 Theme.of(context).textTheme.titleLarge')
  static const double xxxhFontSize = 22;
  @Deprecated('改用 Theme.of(context).textTheme.titleLarge')
  static const double xxxxhFontSize = 24;
  @Deprecated('改用 Theme.of(context).textTheme（無對應角色，未被使用）')
  static const double xxxxxhFontSize = 26;
  @Deprecated('改用 Theme.of(context).textTheme（無對應角色，未被使用）')
  static const double xxxxxxhFontSize = 28;
}
