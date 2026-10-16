import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaruant/features/foundation/extension/snackbar_extension.dart';
import 'package:flutter_restaruant/main.dart' show appRootBuilder;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BuildContextSnackBarX', () {
    testWidgets('在 MaterialApp 中成功顯示 SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => context.showAppSnackBar('Test Message'),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump(); // 開始動畫

      expect(find.text('Test Message'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('連續呼叫時會替換當前 SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => context.showAppSnackBar('First Message'),
                    child: const Text('Show First'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.showAppSnackBar('Second Message'),
                    child: const Text('Show Second'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show First'));
      await tester.pump();
      expect(find.text('First Message'), findsOneWidget);

      await tester.tap(find.text('Show Second'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('Second Message'), findsOneWidget);
    });

    testWidgets('在 CupertinoApp + ScaffoldMessenger 架構下成功顯示 SnackBar 且零崩潰', (
      tester,
    ) async {
      final originalErrorWidgetBuilder = ErrorWidget.builder;
      final originalFlutterErrorOnError = FlutterError.onError;
      final originalPlatformDispatcherOnError =
          ui.PlatformDispatcher.instance.onError;

      try {
        await tester.pumpWidget(
          CupertinoApp(
            builder: appRootBuilder,
            home: CupertinoPageScaffold(
              child: Builder(
                builder: (context) => CupertinoButton(
                  onPressed: () =>
                      context.showAppSnackBar('Cupertino SnackBar'),
                  child: const Text('Trigger'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Trigger'));
        await tester.pump();

        expect(find.text('Cupertino SnackBar'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      } finally {
        ErrorWidget.builder = originalErrorWidgetBuilder;
        FlutterError.onError = originalFlutterErrorOnError;
        ui.PlatformDispatcher.instance.onError =
            originalPlatformDispatcherOnError;
      }
    });

    testWidgets('在無 ScaffoldMessenger 的環境下呼叫安全返回不崩潰', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => context.showAppSnackBar('No Crash'),
              child: const Text('Tap'),
            ),
          ),
        ),
      );

      // 點擊觸發，不應拋出任何異常
      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('當鍵盤彈出（bottom viewInsets > 0）時 SnackBar 浮於鍵盤上方', (
      tester,
    ) async {
      final originalErrorWidgetBuilder = ErrorWidget.builder;
      final originalFlutterErrorOnError = FlutterError.onError;
      final originalPlatformDispatcherOnError =
          ui.PlatformDispatcher.instance.onError;
      addTearDown(() {
        ErrorWidget.builder = originalErrorWidgetBuilder;
        FlutterError.onError = originalFlutterErrorOnError;
        ui.PlatformDispatcher.instance.onError =
            originalPlatformDispatcherOnError;
      });

      const keyboardHeight = 300.0;
      tester.view.viewInsets = FakeViewPadding(
        bottom: keyboardHeight * tester.view.devicePixelRatio,
      );
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        CupertinoApp(
          builder: appRootBuilder,
          home: CupertinoPageScaffold(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () =>
                    context.showAppSnackBar('Above Keyboard SnackBar'),
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);

      final snackBarWidget = tester.widget<SnackBar>(snackBarFinder);
      expect(snackBarWidget.behavior, SnackBarBehavior.floating);
      expect(
        snackBarWidget.margin,
        const EdgeInsets.only(bottom: keyboardHeight),
      );

      final screenBottom =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final snackBarMaterialFinder = find.descendant(
        of: snackBarFinder,
        matching: find.byType(Material),
      );
      final snackBarBottom = tester
          .getBottomLeft(snackBarMaterialFinder.first)
          .dy;
      expect(snackBarBottom, lessThanOrEqualTo(screenBottom - keyboardHeight));
    });
  });
}
