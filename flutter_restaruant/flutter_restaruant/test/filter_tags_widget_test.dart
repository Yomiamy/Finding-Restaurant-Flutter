import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_restaruant/flow/main/view/view_barrel.dart';
import 'package:flutter_restaruant/model/model_barrel.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';

void main() {
  testWidgets('FilterTagsWidget renders FilterChip for active filter configs',
      (WidgetTester tester) async {
    final filterConfigs = FilterConfigs()
      ..price = 2
      ..sortBy = 'rating';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.materialLight,
        home: Scaffold(
          body: FilterTagsWidget(filterConfigs: filterConfigs),
        ),
      ),
    );

    await tester.pump();

    // Verify FilterChip widgets are rendered
    expect(find.byType(FilterChip), findsNWidgets(2));
    expect(find.text(filterConfigs.getPriceDispStr(2)), findsOneWidget);
    expect(find.text(filterConfigs.getSortingRuleDispStr('rating')),
        findsOneWidget);

    // 鎖住著色來源：chip 必須取自 theme 的 colorScheme，而非 Material 預設。
    final chip = tester.widget<FilterChip>(find.byType(FilterChip).first);
    expect(chip.selectedColor, AppTheme.materialLight.colorScheme.primary);
  });

  testWidgets(
      'FilterTagsWidget returns SizedBox.shrink when filter configs empty',
      (WidgetTester tester) async {
    final filterConfigs = FilterConfigs();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterTagsWidget(filterConfigs: filterConfigs),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(FilterChip), findsNothing);
  });
}
