import 'package:package_info_plus/package_info_plus.dart';

class Constants {
  /// [FCM]
  static const fcmNotificationChannelId = 'fcm_notification_channel_id';
  static const fcmNotificationChannelName = 'fcm_notification_channel_name';
  static const fcmNotificationChannelDescription =
      'Android Notification Channel';

  static const fcmNotificationPayloadKeyStoreId = 'store_id';

  /// [Version]
  static late PackageInfo _sPackageInfo;
  static String get version => _sPackageInfo.version;

  /// [SharedPreference]
  static const prefKeyAccountInfo = 'account_info';
  static const prefKeyBiometricAuthSetting = 'biometric_auth_setting';

  /// [AD]
  // PROD AD banner id
  static const adAndroidBannerId = 'ca-app-pub-7910179918263365/3813466391';
  static const adIosBannerId = 'ca-app-pub-7910179918263365/9426979056';
  static const adAndroidInterstitialId =
      'ca-app-pub-7910179918263365/9901799382';
  static const adIosInterstitialId = 'ca-app-pub-7910179918263365/7956300504';

  /// [API]
  static const staticMapApiKey = 'AIzaSyAfe5kOHB_-GPPNovB8iCDimCBnTsW6OYQ';
  static const baseUrl = 'https://api.yelp.com';
  static const googleMapApiUrl = 'https://maps.googleapis.com/maps/api';
  static const googleStaticMap = '$googleMapApiUrl/staticmap';
  static const httpsScheme = 'https';
  static const googleMapHost = 'maps.google.de';
  static const googleMapNavigationPath = '/maps';
  static const googleMapNavigationLatLng = 'q';
  static const googleMapStreetviewLayer = 'layer';
  static const googleMapStreetviewLatLng = 'cbll';
  static const authToken =
      'Bearer 7W-eBLLJ3ij1hx8nKfbihuC9rB-xxX9Uu0c3xmbOgaJMd8p4N0_OXtvmJkKRSiCEd5dhOThCdmudbrqga4ONcugF3GW8I8TaX_Gh6VH1cdUyDdWLNF7mwBv1zROpZnYx';
  static const locale = 'zh_TW';
  static const emailSubject = 'subject';
  static const emailBody = 'body';
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int pageItemCount = 50;

  static Future<void> init() async {
    _sPackageInfo = await PackageInfo.fromPlatform();
  }
}
