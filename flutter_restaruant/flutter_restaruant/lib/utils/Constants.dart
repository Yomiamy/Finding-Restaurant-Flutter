import 'package:package_info_plus/package_info_plus.dart';

class Constants {

  /// [FCM]
  static const FCM_NOTIFICATION_CHANNEL_ID = "fcm_notification_channel_id";
  static const FCM_NOTIFICATION_CHANNEL_NAME = "fcm_notification_channel_name";
  static const FCM_NOTIFICATION_CHANNEL_DESCRIPTION = "Android Notification Channel";

  static const FCM_NOTIFICATION_PAYLOAD_KEY_STORE_ID = "store_id";

  /// [Version]
  static late PackageInfo _sPackageInfo;
  static String get VERSION => _sPackageInfo.version;

  /// [SharedPreference]
  static const PREF_KEY_ACCOUNT_INFO = "account_info";
  static const PREF_KEY_BIOMETRIC_AUTH_SETTING = "biometric_auth_setting";

  /// [AD]
  // PROD AD banner id
  static const AD_ANDROID_BANNER_ID = "ca-app-pub-7910179918263365/3813466391";
  static const AD_IOS_BANNER_ID = "ca-app-pub-7910179918263365/9426979056";
  static const AD_ANDROID_INTERSTITAL_ID = "ca-app-pub-7910179918263365/9901799382";
  static const AD_IOS_INTERSTITAL_ID = "ca-app-pub-7910179918263365/7956300504";

  /// [API]
  static const STATIC_MAP_API_KEY = "AIzaSyAfe5kOHB_-GPPNovB8iCDimCBnTsW6OYQ";
  static const BASE_URL = "https://api.yelp.com";
  static const GOOGLE_MAP_API_URL = "https://maps.googleapis.com/maps/api";
  static const GOOGLE_STATIC_MAP = "$GOOGLE_MAP_API_URL/staticmap";
  static const HTTPS_SCHEME = "https";
  static const GOOGLE_MAP_HOST = "maps.google.de";
  static const GOOGLE_MAP_NAVIGATION_PATH = "/maps";
  static const GOOGLE_MAP_NAVIGATION_LATLNG = "q";
  static const GOOGLE_MAP_STREETVIEW_LAYER = "layer";
  static const GOOGLE_MAP_STREETVIEW_LATLNG = "cbll";
  static const AUTH_TOKEN = "Bearer 4htbz9nLozJ_-Xw-13LpeVWrEIRWZt4IrgTOQXstx7M1DCVeUIoxIZkQ0XVLVEtD2Gy2Vp1FjA2WRz5DOpZMSxHfXVBLR3gi0DeMXIV3X1bCHYoMoJ-_TZLfBn0ZWnYx";
  static const LOCALE = "zh_TW";
  static const int CONNECTION_TIEMOUT = 30000;
  static const int RECEIVE_TIEMOUT = 30000;
  static const int PAGE_ITEM_COUNT = 50;

  static void init() async {
    _sPackageInfo = await PackageInfo.fromPlatform();
  }
}