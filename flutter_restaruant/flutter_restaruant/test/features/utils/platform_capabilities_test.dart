import 'package:flutter/foundation.dart';
import 'package:flutter_restaruant/features/utils/utils_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

/// 鎖住能力矩陣（規格 §1.4、AC-6）。
///
/// Web 列以 `isWeb: true` 注入：`kIsWeb` 是編譯期常數，VM 測試下恆為 false，
/// 但「行動瀏覽器回報 android／iOS」正是最該擋的情境（規格 §5.2），不得略過。
class _Data {
  static const all = (
    ads: true,
    pushNotifications: true,
    mapMode: true,
    camera: true,
  );
  static const none = (
    ads: false,
    pushNotifications: false,
    mapMode: false,
    camera: false,
  );

  static const rows = [
    (isWeb: false, platform: TargetPlatform.android, expected: all),
    (isWeb: false, platform: TargetPlatform.iOS, expected: all),
    (isWeb: false, platform: TargetPlatform.macOS, expected: none),
    (isWeb: false, platform: TargetPlatform.windows, expected: none),
    (isWeb: false, platform: TargetPlatform.linux, expected: none),
    (isWeb: false, platform: TargetPlatform.fuchsia, expected: none),
    (isWeb: true, platform: TargetPlatform.android, expected: none),
    (isWeb: true, platform: TargetPlatform.iOS, expected: none),
    (isWeb: true, platform: TargetPlatform.macOS, expected: none),
  ];
}

void main() {
  group('platformCapabilities 能力矩陣', () {
    for (final row in _Data.rows) {
      test('isWeb=${row.isWeb}, ${row.platform} → ${row.expected}', () {
        debugDefaultTargetPlatformOverride = row.platform;
        try {
          expect(platformCapabilities(isWeb: row.isWeb), row.expected);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  });
}
