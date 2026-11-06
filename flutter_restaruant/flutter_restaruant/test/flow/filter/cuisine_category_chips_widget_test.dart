import 'package:flutter/material.dart';
import 'package:flutter_restaruant/api/dto/dto_barrel.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/flow/filter/view/cuisine_category_chips_widget.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestWidget({
    required List<YelpRestaurantCategoryDto> categories,
    required String? selectedCategory,
    required ValueChanged<String?> onCategorySelected,
    int maxRows = 4,
  }) {
    return MaterialApp(
      theme: AppThemeData.materialLight,
      localizationsDelegates: const [S.delegate],
      home: Scaffold(
        body: CuisineCategoryChipsWidget(
          categories: categories,
          selectedCategory: selectedCategory,
          onCategorySelected: onCategorySelected,
          maxRows: maxRows,
        ),
      ),
    );
  }

  final sampleCuisines = List.generate(
    10,
    (index) => YelpRestaurantCategoryDto(
      alias: 'cuisine_$index',
      title: 'Cuisine $index',
    ),
  );

  group('CuisineCategoryChipsWidget Unit & Widget Tests', () {
    testWidgets('空列表時僅渲染「全部」且只有 1 列', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          categories: const [],
          selectedCategory: null,
          onCategorySelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsOneWidget);
      expect(find.text('All'), findsOneWidget);

      final rows = tester.widgetList<Row>(find.byType(Row));
      expect(rows.length, 1);
    });

    testWidgets('多筆菜系時最多渲染 4 列，且包覆於橫向滾動元件中', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          categories: sampleCuisines,
          selectedCategory: null,
          onCategorySelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scrollView.scrollDirection, Axis.horizontal);

      final rows = tester.widgetList<Row>(find.byType(Row));
      expect(rows.length, 4);

      // 總共有 1 個「全部」+ 10 個菜系 = 11 個 Chip
      expect(find.byType(ChoiceChip), findsNWidgets(11));
    });

    testWidgets('未選中特定菜系時，第一列的第一個是「全部」，第二個是列表第一筆', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          categories: sampleCuisines,
          selectedCategory: null,
          onCategorySelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      final allChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'All'),
      );
      expect(allChip.selected, isTrue);

      final firstRow = tester.widget<Row>(find.byType(Row).first);
      // 第一列 children 包含 SizedBox 間隔，Chip 位於偶數索引
      final firstRowChips = firstRow.children.whereType<ChoiceChip>().toList();
      expect((firstRowChips[0].label as Text).data, 'All');
      expect((firstRowChips[1].label as Text).data, 'Cuisine 0');
    });

    testWidgets('選中特定菜系時，第一列的第一個是「全部」，第二個是被選中的菜系', (tester) async {
      // 選中第 5 個菜系 (cuisine_5)
      await tester.pumpWidget(
        buildTestWidget(
          categories: sampleCuisines,
          selectedCategory: 'cuisine_5',
          onCategorySelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      final allChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'All'),
      );
      expect(allChip.selected, isFalse);

      final selectedChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Cuisine 5'),
      );
      expect(selectedChip.selected, isTrue);

      final firstRow = tester.widget<Row>(find.byType(Row).first);
      final firstRowChips = firstRow.children.whereType<ChoiceChip>().toList();

      expect((firstRowChips[0].label as Text).data, 'All');
      expect((firstRowChips[1].label as Text).data, 'Cuisine 5');
    });

    testWidgets('點擊未選中菜系 Chip 正確回呼其 alias', (tester) async {
      String? selectedResult;
      await tester.pumpWidget(
        buildTestWidget(
          categories: sampleCuisines,
          selectedCategory: null,
          onCategorySelected: (val) {
            selectedResult = val;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cuisine 2'));
      await tester.pumpAndSettle();

      expect(selectedResult, 'cuisine_2');
    });

    testWidgets('點擊「全部」Chip 正確回呼 null 清除選取', (tester) async {
      String? selectedResult = 'cuisine_3';
      await tester.pumpWidget(
        buildTestWidget(
          categories: sampleCuisines,
          selectedCategory: 'cuisine_3',
          onCategorySelected: (val) {
            selectedResult = val;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(selectedResult, isNull);
    });

    testWidgets('點擊已選中的菜系 Chip 正確回呼 null 取消選取', (tester) async {
      String? selectedResult = 'cuisine_4';
      await tester.pumpWidget(
        buildTestWidget(
          categories: sampleCuisines,
          selectedCategory: 'cuisine_4',
          onCategorySelected: (val) {
            selectedResult = val;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cuisine 4'));
      await tester.pumpAndSettle();

      expect(selectedResult, isNull);
    });
  });
}
