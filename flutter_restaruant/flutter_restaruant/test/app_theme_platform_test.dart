import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_restaruant/di/di_barrel.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/main.dart';

/// 鎖住「theme 在 iOS 與 Android 上都生效」。
///
/// iOS 的 `PlatformApp` 走 `CupertinoApp` 分支，`material:` 的 builder
/// 根本不會被呼叫，Material widget 會退回 Flutter 預設色票。`main.dart`
/// 因此額外用 `builder:` 包一層 `Theme` —— 若那層被移除，本測試會在
/// iOS case 變紅。
///
/// 直接掛載 `FindingRestaruantApp`（而非在測試裡重建一份 `PlatformApp`），
/// 這樣 `main.dart` 的接線若被改壞，測試才抓得到。
void main() {
  // 進入點的 route 是 SplashPage，其 3 秒延遲結束後會導向需要 DI 的頁面。
  setUpAll(setupInjection);
  tearDownAll(getIt.reset);

  for (final target in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('AppThemeData 在 $target 上可被解析', (tester) async {
      await tester.pumpWidget(Theme(
        data: ThemeData(platform: target),
        child: const FindingRestaruantApp(),
      ));

      // 由 navigatorKey 取得 route 之下的 context，確保讀到的是 app 實際
      // 套用的 theme，而非測試自建的外層 Theme。
      final scheme = Theme.of(navigatorKey.currentContext!).colorScheme;

      expect(scheme.primary, AppThemeData.materialLight.colorScheme.primary);

      // SplashPage 的 3 秒延遲不排掉會留下 pending timer，測試 framework 會報錯。
      await tester.pump(const Duration(seconds: 3));
    });
  }
}
