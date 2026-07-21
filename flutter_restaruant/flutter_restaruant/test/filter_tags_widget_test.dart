import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_restaruant/flow/main/view/filter_tags_widget.dart';
import 'package:flutter_restaruant/model/filter_configs.dart';

void main() {
  testWidgets('FilterTagsWidget renders FilterChip for active filter configs',
      (WidgetTester tester) async {
    final filterConfigs = FilterConfigs()
      ..price = 2
      ..sortBy = 'rating';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterTagsWidget(filterConfigs: filterConfigs),
        ),
      ),
    );

    await tester.pump();

    // Verify FilterChip widgets are rendered
    expect(find.byType(FilterChip), findsNWidgets(2));
    expect(find.text(filterConfigs.getPriceDispStr(2)), findsOneWidget);
    expect(find.text(filterConfigs.getSortingRuleDispStr('rating')), findsOneWidget);
  });

  testWidgets('FilterTagsWidget returns SizedBox.shrink when filter configs empty',
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
