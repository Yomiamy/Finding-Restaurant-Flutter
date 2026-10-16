import 'package:flutter/foundation.dart';

/// Developer ID（DMG 直接分發）建置旗標，由 `scripts/release_macos.sh` 以
/// `--dart-define=DEVELOPER_ID_BUILD=true` 注入。
const _kDeveloperIdBuild = bool.fromEnvironment('DEVELOPER_ID_BUILD');

/// 平台能力閘門：回答「此平台有沒有廣告／推播／地圖模式／拍照／Apple 登入」的唯一一處。
///
/// 前四項目前同為「原生 Android 或原生 iOS」，但成立理由不同（AdMob 套件只支援
/// android／ios；D-9.7 macOS 不做推播；Web 地圖待 E-9.3 的 Maps JS API key；
/// `image_picker_macos` 未設 `cameraDelegate` 時拍照會拋 `StateError`）。
/// Apple 登入為原生 iOS 與 macOS，但 Developer ID 分發的 macOS 除外：Apple 不允許
/// Developer ID profile 授權 `com.apple.developer.applesignin`（僅 Mac App Store 可）。
/// 呼叫點只讀能力名稱、不讀平台名稱，日後翻轉某一項只改這裡。
///
/// [isWeb]、[developerIdBuild] 僅供測試注入：兩者皆為編譯期常數，VM 測試下恆為 false。
({
  bool ads,
  bool pushNotifications,
  bool mapMode,
  bool camera,
  bool appleSignIn,
})
platformCapabilities({
  @visibleForTesting bool isWeb = kIsWeb,
  @visibleForTesting bool developerIdBuild = _kDeveloperIdBuild,
}) {
  final platform = defaultTargetPlatform;
  // 先判 Web：Web 上 defaultTargetPlatform 是瀏覽器所在 OS，行動瀏覽器會
  // 回報 android／iOS。白名單：windows／linux／fuchsia 與未來新平台一律關閉。
  final nativeMobile =
      !isWeb &&
      (platform == TargetPlatform.android || platform == TargetPlatform.iOS);
  final appleSignIn =
      !isWeb &&
      (platform == TargetPlatform.iOS ||
          (platform == TargetPlatform.macOS && !developerIdBuild));
  return (
    ads: nativeMobile,
    pushNotifications: nativeMobile,
    mapMode: nativeMobile,
    camera: nativeMobile,
    appleSignIn: appleSignIn,
  );
}
