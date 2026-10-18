import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaruant/features/foundation/style/app_scroll_behavior.dart';
import 'package:flutter_restaruant/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppScrollBehavior Tests', () {
    test('dragDevices keeps every default device and adds mouse', () {
      final devices = const AppScrollBehavior().dragDevices;

      // 預設集合含 Voice Access 用的 unknown，任何一項被漏掉都是回歸
      expect(devices, containsAll(const MaterialScrollBehavior().dragDevices));
      expect(devices, contains(PointerDeviceKind.unknown));
      expect(devices, contains(PointerDeviceKind.mouse));
    });

    // CupertinoApp 預設的 CupertinoScrollBehavior 不含 mouse，iOS/macOS
    // 只能靠 appRootBuilder 注入的這層 ScrollConfiguration 支援滑鼠拖曳。
    testWidgets('appRootBuilder enables mouse drag scrolling on the Cupertino branch', (
      tester,
    ) async {
      // debug 模式下 appRootBuilder 會初始化 inspector，改寫這些全域 handler
      final originalErrorWidgetBuilder = ErrorWidget.builder;
      final originalFlutterErrorOnError = FlutterError.onError;
      final originalPlatformDispatcherOnError =
          PlatformDispatcher.instance.onError;

      try {
        final scrollController = ScrollController();

        await tester.pumpWidget(
          CupertinoApp(
            builder: appRootBuilder,
            home: ListView.builder(
              controller: scrollController,
              itemCount: 100,
              itemBuilder: (context, index) => SizedBox(
                height: 50,
                child: Text('Item $index'),
              ),
            ),
          ),
        );

        expect(scrollController.offset, 0.0);

        // 分段移動：inspector 的 tap recognizer 會與 drag 競爭，drag 越過
        // slop 勝出前的位移不計入捲動，單次大位移會被整段吃掉。
        final gesture = await tester.startGesture(
          const Offset(200, 300),
          kind: PointerDeviceKind.mouse,
        );
        for (var i = 0; i < 5; i++) {
          await gesture.moveBy(const Offset(0, -40));
          await tester.pump();
        }
        await gesture.up();
        await tester.pumpAndSettle();

        expect(scrollController.offset, greaterThan(0.0));
      } finally {
        ErrorWidget.builder = originalErrorWidgetBuilder;
        FlutterError.onError = originalFlutterErrorOnError;
        PlatformDispatcher.instance.onError = originalPlatformDispatcherOnError;
      }
    });
  });
}
