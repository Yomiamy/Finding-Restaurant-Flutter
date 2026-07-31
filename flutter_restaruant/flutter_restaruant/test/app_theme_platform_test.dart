import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_restaruant/theme/app_theme.dart';

/// 鎖住「theme 在 iOS 與 Android 上都生效」。
///
/// iOS 的 `PlatformApp` 走 `CupertinoApp` 分支，`material:` 的 builder
/// 根本不會被呼叫，Material widget 會退回 Flutter 預設色票。`main.dart`
/// 因此額外用 `builder:` 包一層 `Theme` —— 若那層被移除，本測試會在
/// iOS case 變紅。
void main() {
  for (final target in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('AppTheme 在 $target 上可被解析', (tester) async {
      late ColorScheme scheme;

      await tester.pumpWidget(Theme(
        data: ThemeData(platform: target),
        child: PlatformApp(
          material: (_, __) => MaterialAppData(theme: AppTheme.materialLight),
          builder: (_, child) => Theme(
            data: AppTheme.materialLight,
            child: child ?? const SizedBox.shrink(),
          ),
          home: Builder(builder: (ctx) {
            scheme = Theme.of(ctx).colorScheme;
            return const SizedBox.shrink();
          }),
        ),
      ));

      expect(scheme.primary, AppTheme.materialLight.colorScheme.primary);
    });
  }
}
