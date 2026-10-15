import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_restaruant/features/foundation/style/app_scroll_behavior.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppScrollBehavior Tests', () {
    test('dragDevices includes mouse, touch, trackpad and stylus', () {
      const behavior = AppScrollBehavior();
      final devices = behavior.dragDevices;

      expect(devices, contains(PointerDeviceKind.mouse));
      expect(devices, contains(PointerDeviceKind.touch));
      expect(devices, contains(PointerDeviceKind.trackpad));
      expect(devices, contains(PointerDeviceKind.stylus));
      expect(devices, contains(PointerDeviceKind.invertedStylus));
    });

    testWidgets('Scrollable inside AppScrollBehavior allows mouse drag scrolling', (
      tester,
    ) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          scrollBehavior: const AppScrollBehavior(),
          home: Scaffold(
            body: ListView.builder(
              controller: scrollController,
              itemCount: 100,
              itemBuilder: (context, index) => SizedBox(
                height: 50,
                child: Text('Item $index'),
              ),
            ),
          ),
        ),
      );

      expect(scrollController.offset, 0.0);

      // 模擬滑鼠在列表中心按下並向上拖曳
      final gesture = await tester.startGesture(
        const Offset(200, 300),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // 滑鼠拖曳後 offset 應大於 0
      expect(scrollController.offset, greaterThan(0.0));
    });
  });
}
