import 'dart:ui' as ui;
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
      // lib/di/inspector.dart 的 captureUncaughtErrors: true 會在
      // FlutterInspector 建構子內立刻 attach 三個全域 error hook
      // （FlutterError.onError／PlatformDispatcher.onError／
      // ErrorWidget.builder）。`inspector` 是頂層 lazy final，全專案
      // 只有本測試會 mount 真實 FindingRestaruantApp，故首次求值必在
      // 此發生。flutter_test 對每個測試各自比對 pumpWidget 前後的
      // ErrorWidget.builder，變動會被判定失敗——package:test 的
      // tearDown() 在此驗證之後才執行，太晚救不了，必須在本 callback
      // 結尾、pumpWidget 之後手動復原。
      final originalErrorWidgetBuilder = ErrorWidget.builder;
      final originalFlutterErrorOnError = FlutterError.onError;
      final originalPlatformDispatcherOnError =
          ui.PlatformDispatcher.instance.onError;

      // try/finally：測試主體若中途失敗（例如 expect 不通過），仍要復原
      // 三個全域 hook，避免汙染下一次迭代（Android case）的 before/after
      // 快照、掩蓋真正的失敗原因。
      try {
        await tester.pumpWidget(
          Theme(
            data: ThemeData(platform: target),
            child: const FindingRestaruantApp(),
          ),
        );

        // 由 navigatorKey 取得 route 之下的 context，確保讀到的是 app 實際
        // 套用的 theme，而非測試自建的外層 Theme。
        final scheme = Theme.of(navigatorKey.currentContext!).colorScheme;

        expect(scheme.primary, AppThemeData.materialLight.colorScheme.primary);

        // SplashPage 的 3 秒延遲不排掉會留下 pending timer，測試 framework 會報錯。
        await tester.pump(const Duration(seconds: 3));
      } finally {
        ErrorWidget.builder = originalErrorWidgetBuilder;
        FlutterError.onError = originalFlutterErrorOnError;
        ui.PlatformDispatcher.instance.onError =
            originalPlatformDispatcherOnError;
      }
    });
  }
}
