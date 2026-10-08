import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaruant/flow/signinup/view/third_party_sign_in_widget.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_button/sign_in_button.dart';

/// 鎖住「Apple 登入按鈕的顯示判準是平台能力，不是單一 OS」。
///
/// 此判準原為 `Platform.isIOS`，使 macOS 上明明支援 Sign in with Apple
/// 卻不顯示按鈕；改為 `defaultTargetPlatform` 後放寬為 iOS 或 macOS。
///
/// 本測試存在的理由：macOS target 目前尚未建立，AC-5 無法靠人工在真機確認，
/// 若無此測試，日後有人改回 `isIOS` 不會有任何東西轉紅。
///
/// 另一個前提是 `Platform.isIOS` 讀的是**真實** OS、widget test 無法覆寫；
/// 換成 `defaultTargetPlatform` 才解鎖 `debugDefaultTargetPlatformOverride`。
void main() {
  /// 以 `Buttons` enum 定位而非 `find.text`：後者依賴 `S.current` 已載入，
  /// 在 l10n 尚未就緒時求值會拋錯；比對 enum 不碰 l10n，較穩。
  Finder buttonFinder(Buttons button) => find.byWidgetPredicate(
    (widget) => widget is SignInButton && widget.button == button,
  );

  Future<void> pumpWidget(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [S.delegate],
      home: Scaffold(
        body: ThirdPartySignInWidget(
          onGoogleSignIn: () {},
          onAppleSignIn: () {},
        ),
      ),
    ),
  );

  group('ThirdPartySignInWidget 的 Apple 登入顯示判準', () {
    // 支援 Sign in with Apple 的平台：按鈕必須出現。
    for (final target in [TargetPlatform.iOS, TargetPlatform.macOS]) {
      testWidgets('$target 顯示 Apple 登入按鈕', (tester) async {
        debugDefaultTargetPlatformOverride = target;
        try {
          await pumpWidget(tester);
          await tester.pumpAndSettle();

          expect(buttonFinder(Buttons.apple), findsOneWidget);
          // Google 按鈕不受平台判準影響，全平台恆顯示。
          expect(buttonFinder(Buttons.google), findsOneWidget);
        } finally {
          // 不復原會汙染後續 case 的平台判定。
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }

    testWidgets('android 不顯示 Apple 登入按鈕，但仍顯示 Google', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await pumpWidget(tester);
        await tester.pumpAndSettle();

        expect(buttonFinder(Buttons.apple), findsNothing);
        expect(buttonFinder(Buttons.google), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
