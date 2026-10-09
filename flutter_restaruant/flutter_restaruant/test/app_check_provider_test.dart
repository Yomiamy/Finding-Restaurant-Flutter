import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_restaruant/main.dart';
import 'package:flutter_test/flutter_test.dart';

/// 鎖住 AC-8 的 release 列：`providerApple` 同時作用於 iOS 與 macOS，
/// fallback provider 只能給 macOS（規格 §5.4：套到 iOS 會改變 iOS 行為，
/// 且需另在 Console 登記 DeviceCheck 金鑰）。debug 分支與 providerAndroid
/// 未改動，由 diff 審查確認。
void main() {
  test('iOS release 維持 AppleAppAttestProvider', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      expect(releaseAppleAppCheckProvider(), isA<AppleAppAttestProvider>());
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('macOS release 改用 AppleAppAttestWithDeviceCheckFallbackProvider', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      expect(
        releaseAppleAppCheckProvider(),
        isA<AppleAppAttestWithDeviceCheckFallbackProvider>(),
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
