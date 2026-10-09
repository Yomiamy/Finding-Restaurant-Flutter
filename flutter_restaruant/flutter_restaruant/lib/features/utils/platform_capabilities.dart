import 'package:flutter/foundation.dart';

/// 平台能力閘門：回答「此平台有沒有廣告／推播／地圖模式／拍照」的唯一一處。
///
/// 四項目前同為「原生 Android 或原生 iOS」，但成立理由不同（AdMob 套件只支援
/// android／ios；D-9.7 macOS 不做推播；Web 地圖待 E-9.3 的 Maps JS API key；
/// `image_picker_macos` 未設 `cameraDelegate` 時拍照會拋 `StateError`）。
/// 呼叫點只讀能力名稱、不讀平台名稱，日後翻轉某一項只改這裡。
///
/// [isWeb] 僅供測試注入：`kIsWeb` 是編譯期常數，VM 測試下恆為 false。
({bool ads, bool pushNotifications, bool mapMode, bool camera})
platformCapabilities({@visibleForTesting bool isWeb = kIsWeb}) {
  final platform = defaultTargetPlatform;
  // 先判 Web：Web 上 defaultTargetPlatform 是瀏覽器所在 OS，行動瀏覽器會
  // 回報 android／iOS。白名單：windows／linux／fuchsia 與未來新平台一律關閉。
  final nativeMobile =
      !isWeb &&
      (platform == TargetPlatform.android || platform == TargetPlatform.iOS);
  return (
    ads: nativeMobile,
    pushNotifications: nativeMobile,
    mapMode: nativeMobile,
    camera: nativeMobile,
  );
}
