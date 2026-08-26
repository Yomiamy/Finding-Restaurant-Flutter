import 'package:flutter/material.dart';
import 'package:flutter_restaruant/component/empty_data_widget.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmptyDataWidget Tests', () {
    testWidgets('渲染預設圖示與多語系標題', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [S.delegate],
          home: Scaffold(body: EmptyDataWidget()),
        ),
      );

      expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
      expect(find.text('No Data Available'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('EmptyDataWidget.withDefaults 包含多語系副標題', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          home: Scaffold(body: EmptyDataWidget.withDefaults()),
        ),
      );

      expect(find.text('No Data Available'), findsOneWidget);
      expect(
        find.text('Try adjusting your keywords or filters'),
        findsOneWidget,
      );
    });

    testWidgets('渲染自訂標題、副標題與圖示', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [S.delegate],
          home: Scaffold(
            body: EmptyDataWidget(
              title: '查無任何餐廳',
              subtitle: '請嘗試放寬篩選條件',
              icon: Icons.search_off,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('查無任何餐廳'), findsOneWidget);
      expect(find.text('請嘗試放寬篩選條件'), findsOneWidget);
    });

    testWidgets('提供 onRetry 時渲染重試按鈕並可正常點擊觸發', (tester) async {
      var retryCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          home: Scaffold(
            body: EmptyDataWidget(
              onRetry: () {
                retryCount++;
              },
            ),
          ),
        ),
      );

      final retryBtnFinder = find.byType(OutlinedButton);
      expect(retryBtnFinder, findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(retryBtnFinder);
      await tester.pump();

      expect(retryCount, 1);
    });

    testWidgets('向後相容 message 參數', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [S.delegate],
          home: Scaffold(body: EmptyDataWidget(message: '舊版訊息')),
        ),
      );

      expect(find.text('舊版訊息'), findsOneWidget);
    });
  });
}
