import 'package:flutter/material.dart';
import 'package:flutter_restaruant/features/foundation/extension/widget_extension.dart';
import 'package:flutter_test/flutter_test.dart';

class _HostWidget extends StatefulWidget {
  const _HostWidget({required this.onState});

  final void Function(_HostWidgetState state) onState;

  @override
  State<_HostWidget> createState() => _HostWidgetState();
}

class _HostWidgetState extends State<_HostWidget> {
  @override
  void initState() {
    super.initState();
    widget.onState(this);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  group('StateFrameCallbackExtension', () {
    testWidgets('runAfterFrame 在該幀後執行 action', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _HostWidget(
          onState: (state) => state.runAfterFrame(() => called = true),
        ),
      );

      expect(called, isTrue);
    });

    testWidgets('runAfterFrame 在 unmount 後不執行 action', (tester) async {
      var called = false;
      late _HostWidgetState captured;
      await tester.pumpWidget(
        _HostWidget(onState: (state) => captured = state),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      captured.runAfterFrame(() => called = true);
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets('waitForFrame 掛載時回傳 true', (tester) async {
      late Future<bool> result;
      await tester.pumpWidget(
        _HostWidget(onState: (state) => result = state.waitForFrame()),
      );

      expect(await result, isTrue);
    });

    testWidgets('waitForFrame 於 unmount 後回傳 false', (tester) async {
      late _HostWidgetState captured;
      await tester.pumpWidget(
        _HostWidget(onState: (state) => captured = state),
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
