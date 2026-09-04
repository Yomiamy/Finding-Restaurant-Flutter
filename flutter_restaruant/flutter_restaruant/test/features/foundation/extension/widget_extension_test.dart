import 'package:flutter/material.dart';
import 'package:flutter_restaruant/features/foundation/extension/widget_extension.dart';
import 'package:flutter_test/flutter_test.dart';

class _HostWidget extends StatelessWidget {
  const _HostWidget({required this.onContext});

  final void Function(BuildContext context) onContext;

  @override
  Widget build(BuildContext context) {
    onContext(context);
    return const SizedBox.shrink();
  }
}

void main() {
  group('ContextFrameCallbackExtension', () {
    testWidgets('runAfterFrame 在該幀後執行 action', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _HostWidget(
          onContext: (context) => context.runAfterFrame(() => called = true),
        ),
      );

      expect(called, isTrue);
    });

    testWidgets('runAfterFrame 在 unmount 後不執行 action', (tester) async {
      var called = false;
      late BuildContext captured;
      await tester.pumpWidget(
        _HostWidget(onContext: (context) => captured = context),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      captured.runAfterFrame(() => called = true);
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets('waitForFrame 掛載時回傳 true', (tester) async {
      late Future<bool> result;
      await tester.pumpWidget(
        _HostWidget(onContext: (context) => result = context.waitForFrame()),
      );

      expect(await result, isTrue);
    });

    testWidgets('waitForFrame 於 unmount 後回傳 false', (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        _HostWidget(onContext: (context) => captured = context),
      );

      await tester.pumpWidget(const SizedBox.shrink());

      // 已 unmount 時必須立刻返回 false，不得等待不會到來的 frame。
      expect(
        await captured.waitForFrame().timeout(const Duration(seconds: 1)),
        isFalse,
      );
    });
  });
}
