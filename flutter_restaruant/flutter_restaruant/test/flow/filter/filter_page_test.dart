import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/features/utils/utils_barrel.dart';
import 'package:flutter_restaruant/flow/filter/view/filter_page.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_restaruant/model/model_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FilterPage Widget Tests', () {
    testWidgets('渲染價格、營業時間、排序規則區塊與底部套用按鈕', (tester) async {
      final initialConfigs = FilterConfigs();
      final arguments = Tuple2<FilterConfigs, dynamic>(initialConfigs, null);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeData.materialLight,
          localizationsDelegates: const [S.delegate],
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FilterPage(),
                        settings: RouteSettings(
                          name: FilterPage.routeName,
                          arguments: arguments,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Filter'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Rules'), findsOneWidget);
      expect(find.text('Price Rule'), findsOneWidget);
      expect(find.text('Business Hour'), findsOneWidget);
      expect(find.text('Sorting Rule'), findsOneWidget);
      expect(find.byType(CupertinoDatePicker), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('點擊底部套用按鈕正確返回 FilterConfigs 結果', (tester) async {
      final initialConfigs = FilterConfigs();
      final arguments = Tuple2<FilterConfigs, dynamic>(initialConfigs, null);
      Tuple2<FilterConfigs, dynamic>? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeData.materialLight,
          localizationsDelegates: const [S.delegate],
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result =
                        (await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const FilterPage(),
                                settings: RouteSettings(
                                  name: FilterPage.routeName,
                                  arguments: arguments,
                                ),
                              ),
                            ))
                            as Tuple2<FilterConfigs, dynamic>?;
                  },
                  child: const Text('Open Filter'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Tap on '$$' price segment
      await tester.tap(find.text(r'$$'));
      await tester.pumpAndSettle();

      // Tap on 'Apply' filled button
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.item1.priceIndex, 1);
    });
  });
}
