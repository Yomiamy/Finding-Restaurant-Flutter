import 'package:flutter/foundation.dart';
import 'package:flutter_restaruant/features/utils/utils_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

/// 鎖住能力矩陣（規格 §1.4、AC-6）。
///
/// Web 列以 `isWeb: true` 注入：`kIsWeb` 是編譯期常數，VM 測試下恆為 false，
/// 但「行動瀏覽器回報 android／iOS」正是最該擋的情境（規格 §5.2），不得略過。
/// Developer ID 列同理以 `developerIdBuild: true` 注入。
class _Data {
  static const mobile = (
    ads: true,
    pushNotifications: true,
    mapMode: true,
    camera: true,
    appleSignIn: false,
  );
  static const ios = (
    ads: true,
    pushNotifications: true,
    mapMode: true,
    camera: true,
    appleSignIn: true,
  );
  static const macos = (
    ads: false,
    pushNotifications: false,
    mapMode: false,
    camera: false,
    appleSignIn: true,
  );
  static const none = (
    ads: false,
    pushNotifications: false,
    mapMode: false,
    camera: false,
    appleSignIn: false,
  );

  static const rows = [
    (
      isWeb: false,
      devId: false,
      platform: TargetPlatform.android,
      expected: mobile,
    ),
    (isWeb: false, devId: false, platform: TargetPlatform.iOS, expected: ios),
    (
      isWeb: false,
      devId: false,
      platform: TargetPlatform.macOS,
      expected: macos,
    ),
    (isWeb: false, devId: true, platform: TargetPlatform.macOS, expected: none),
    (
      isWeb: false,
      devId: false,
      platform: TargetPlatform.windows,
      expected: none,
    ),
    (
      isWeb: false,
      devId: false,
      platform: TargetPlatform.linux,
      expected: none,
    ),
    (
      isWeb: false,
      devId: false,
      platform: TargetPlatform.fuchsia,
      expected: none,
    ),
    (
      isWeb: true,
      devId: false,
      platform: TargetPlatform.android,
      expected: none,
    ),
    (isWeb: true, devId: false, platform: TargetPlatform.iOS, expected: none),
    (isWeb: true, devId: false, platform: TargetPlatform.macOS, expected: none),
  ];
}

void main() {
  group('platformCapabilities 能力矩陣', () {
    for (final row in _Data.rows) {
      test(
        'isWeb=${row.isWeb}, devId=${row.devId}, ${row.platform} → ${row.expected}',
        () {
          debugDefaultTargetPlatformOverride = row.platform;
          try {
            expect(
              platformCapabilities(
                isWeb: row.isWeb,
                developerIdBuild: row.devId,
              ),
              row.expected,
            );
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        },
      );
    }
  });
}
