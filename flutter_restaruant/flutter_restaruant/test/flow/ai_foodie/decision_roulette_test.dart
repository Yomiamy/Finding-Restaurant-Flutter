import 'package:flutter/material.dart';
import 'package:flutter_restaruant/flow/ai_foodie/view/decision_roulette_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DecisionRouletteDialog 正常渲染標題與選項按鈕', (tester) async {
    String? selectedWinner;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DecisionRouletteDialog(
            title: '今晚吃什麼大轉盤',
            options: const ['野武士居酒屋', '狸御殿和食酒場', '鳥幸本格炭火串燒'],
            onWinnerSelected: (winner) {
              selectedWinner = winner;
            },
          ),
        ),
      ),
    );

    expect(find.text('今晚吃什麼大轉盤'), findsOneWidget);
    expect(find.text('🎲 轉動命運！'), findsOneWidget);

    // 點擊轉動按鈕
    await tester.tap(find.text('🎲 轉動命運！'));
    await tester.pump();

    // 狀態變為轉動中
    expect(find.text('轉動中...'), findsOneWidget);

    // 等待旋轉動畫完成
    await tester.pumpAndSettle();

    expect(selectedWinner, isNotNull);
    expect(
      ['野武士居酒屋', '狸御殿和食酒場', '鳥幸本格炭火串燒'],
      contains(selectedWinner),
    );
  });
}
