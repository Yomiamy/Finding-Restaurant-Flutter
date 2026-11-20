import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/flow/filter/view/radius_chips_widget.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestWidget({
    required int? selectedRadius,
    required ValueChanged<int?> onRadiusSelected,
    Locale? locale,
  }) {
    return MaterialApp(
      locale: locale,
      theme: AppThemeData.materialLight,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: RadiusChipsWidget(
          selectedRadius: selectedRadius,
          onRadiusSelected: onRadiusSelected,
        ),
      ),
    );
  }

  group('RadiusChipsWidget Widget Tests', () {
    testWidgets('預設 selectedRadius 為 null 時選中 Unlimited 並渲染 8 個距離選項', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(selectedRadius: null, onRadiusSelected: (_) {}),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsNWidgets(8));
      for (final label in const [
        'Unlimited',
        '500 m',
        '1 km',
        '3 km',
        '5 km',
        '10 km',
        '20 km',
        '40 km',
      ]) {
        expect(find.text(label), findsOneWidget);
      }

      final unlimitedChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Unlimited'),
      );
      expect(unlimitedChip.selected, isTrue);
    });

    testWidgets('傳入 selectedRadius 為 5000 時選中 5 km 且 Unlimited 未選中', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(selectedRadius: 5000, onRadiusSelected: (_) {}),
      );
      await tester.pumpAndSettle();

      final unlimitedChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Unlimited'),
      );
      final fiveKmChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '5 km'),
      );
      expect(unlimitedChip.selected, isFalse);
      expect(fiveKmChip.selected, isTrue);
    });

    testWidgets('點擊未選中的距離 Chip (3 km) 回呼對應公尺數 3000', (tester) async {
      int? selectedResult;
      await tester.pumpWidget(
        buildTestWidget(
          selectedRadius: null,
          onRadiusSelected: (val) => selectedResult = val,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('3 km'));
      await tester.pumpAndSettle();

      expect(selectedResult, 3000);
    });

    testWidgets('再次點擊已選中的距離 Chip (3 km) 回呼 null 取消選取', (tester) async {
      int? selectedResult = 3000;
      await tester.pumpWidget(
        buildTestWidget(
          selectedRadius: 3000,
          onRadiusSelected: (val) => selectedResult = val,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('3 km'));
      await tester.pumpAndSettle();

      expect(selectedResult, isNull);
    });

    testWidgets('從 5000 點擊 Unlimited 回呼 null，且原為 null 時點擊維持不變', (tester) async {
      int? selectedResult = 5000;
      await tester.pumpWidget(
        buildTestWidget(
          selectedRadius: 5000,
          onRadiusSelected: (val) => selectedResult = val,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unlimited'));
      await tester.pumpAndSettle();
      expect(selectedResult, isNull);

      int callCount = 0;
      await tester.pumpWidget(
        buildTestWidget(
          selectedRadius: null,
          onRadiusSelected: (val) {
            callCount++;
            selectedResult = val;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unlimited'));
      await tester.pumpAndSettle();
      expect(callCount, 0);
      expect(selectedResult, isNull);
    });

    testWidgets('傳入非預設半徑 2500 時顯示選中 Chip，點擊該 Chip 回呼 null 清除', (tester) async {
      int? selectedResult = 2500;
      await tester.pumpWidget(
        buildTestWidget(
          selectedRadius: 2500,
          onRadiusSelected: (val) => selectedResult = val,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsNWidgets(9));
      final customChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '2500 m'),
      );
      expect(customChip.selected, isTrue);

      final unlimitedChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Unlimited'),
      );
      expect(unlimitedChip.selected, isFalse);

      await tester.tap(find.text('2500 m'));
      await tester.pumpAndSettle();
      expect(selectedResult, isNull);
    });

    testWidgets('傳入 selectedRadius <= 0 時選中 Unlimited 且不渲染自訂 Chip', (
      tester,
    ) async {
      for (final invalidRadius in const [0, -100]) {
        await tester.pumpWidget(
          buildTestWidget(
            selectedRadius: invalidRadius,
            onRadiusSelected: (_) {},
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ChoiceChip), findsNWidgets(8));
        final unlimitedChip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'Unlimited'),
        );
        expect(unlimitedChip.selected, isTrue);
      }
    });

    testWidgets('繁體中文語系正確顯示不限與公尺／公里單位標籤', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          selectedRadius: 2500,
          onRadiusSelected: (_) {},
          locale: const Locale('zh', 'TW'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('不限'), findsOneWidget);
      expect(find.text('500 公尺'), findsOneWidget);
      expect(find.text('3 公里'), findsOneWidget);
      expect(find.text('2500 公尺'), findsOneWidget);
    });
  });
}
