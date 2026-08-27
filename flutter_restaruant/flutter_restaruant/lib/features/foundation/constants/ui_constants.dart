import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../style/style_barrel.dart';

class UIConstants {
  /// [FCM]
  static const fcmNotificationIcon = '@mipmap/ic_launcher';

  @Deprecated('Use S.current instead')
  static const loginTitle = '登入';

  @Deprecated('Use S.current.favorite_stores instead')
  static const favorTitle = '我喜好的店家';

  static const String noImage = 'images/empty.png';

  @Deprecated('Use SizedBox.shrink() directly instead')
  static const emptyWidget = SizedBox(height: ThemeSize.zero);

  static const mapDefaultLocation = LatLng(25.048036, 121.517063);
  static const mapCenterLocMarkId = 'MAP_CENTER_LOC_MARK_ID';
}
