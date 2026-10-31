import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaruant/api/dto/dto_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/yelp_category_repository.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/features/utils/utils_barrel.dart';
import 'package:flutter_restaruant/flow/filter/view/filter_page.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_restaruant/models/model_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockYelpCategoryRepository extends Mock
    implements YelpCategoryRepository {}

void main() {
  late _MockYelpCategoryRepository mockCategoryRepo;

  final testCuisines = [
    const YelpRestaurantCategoryDto(alias: 'taiwanese', title: 'Taiwanese'),
    const YelpRestaurantCategoryDto(alias: 'japanese', title: 'Japanese'),
    const YelpRestaurantCategoryDto(alias: 'italian', title: 'Italian'),
  ];

  setUp(() {
    mockCategoryRepo = _MockYelpCategoryRepository();
    when(
      () => mockCategoryRepo.fetchCuisineCategories(
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer((_) async => testCuisines);
  });

  Widget buildTestApp({
    required Tuple2<FilterConfigs, dynamic> arguments,
    void Function(Tuple2<FilterConfigs, dynamic>? result)? onResult,
    YelpCategoryRepository? categoryRepo,
  }) {
    return MaterialApp(
      theme: AppThemeData.materialLight,
      localizationsDelegates: const [S.delegate],
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                final res = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FilterPage(
                      categoryRepository: categoryRepo ?? mockCategoryRepo,
                    ),
                    settings: RouteSettings(
                      name: FilterPage.routeName,
                      arguments: arguments,
                    ),
                  ),
                );
                onResult?.call(res as Tuple2<FilterConfigs, dynamic>?);
              },
              child: const Text('Open Filter'),
            ),
          );
        },
      ),
    );
  }

  group('FilterPage Widget Tests', () {
    testWidgets('渲染價格、營業時間、餐飲菜系分類、排序規則區塊與底部套用按鈕', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final initialConfigs = FilterConfigs();
      final arguments = Tuple2<FilterConfigs, dynamic>(initialConfigs, null);

      await tester.pumpWidget(buildTestApp(arguments: arguments));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Rules'), findsOneWidget);
      expect(find.text('Price Rule'), findsOneWidget);
      expect(find.text('Business Hour'), findsOneWidget);
      expect(find.text('Cuisine Category'), findsOneWidget);
      expect(find.text('Sorting Rule'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Taiwanese'), findsOneWidget);
      expect(find.text('Japanese'), findsOneWidget);
      expect(find.text('Italian'), findsOneWidget);
      expect(find.byType(CupertinoDatePicker), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('點擊底部套用按鈕正確返回 FilterConfigs 結果 (包含菜系分類)', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final initialConfigs = FilterConfigs();
      final arguments = Tuple2<FilterConfigs, dynamic>(initialConfigs, null);
      Tuple2<FilterConfigs, dynamic>? result;

      await tester.pumpWidget(
        buildTestApp(
          arguments: arguments,
          onResult: (res) {
            result = res;
          },
        ),
      );

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Tap on '$$' price segment
      await tester.tap(find.text(r'$$'));
      await tester.pumpAndSettle();

      // Tap on 'Japanese' cuisine chip
      await tester.scrollUntilVisible(find.text('Japanese'), 100);
      await tester.tap(find.text('Japanese'));
      await tester.pumpAndSettle();

      // Tap on 'Apply' filled button
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.item1.priceIndex, 1);
      expect(result!.item1.categories, 'japanese');
    });

    testWidgets('初始傳入已選取菜系時，正確預選對應 Chip', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final initialConfigs = FilterConfigs(categories: 'italian');
      final arguments = Tuple2<FilterConfigs, dynamic>(initialConfigs, null);
      Tuple2<FilterConfigs, dynamic>? result;

      await tester.pumpWidget(
        buildTestApp(
          arguments: arguments,
          onResult: (res) {
            result = res;
          },
        ),
      );

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Italian'), 100);

      // 驗證 Italian ChoiceChip 處於選取狀態
      final italianChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Italian'),
      );
      expect(italianChip.selected, isTrue);

      final allChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'All'),
      );
      expect(allChip.selected, isFalse);

      // 點擊 "All" 清除選取
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      final allChipAfter = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'All'),
      );
      expect(allChipAfter.selected, isTrue);

      // 套用
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.item1.categories, isNull);
    });

    testWidgets('若 Repository 未注入且 GetIt 未註冊，優雅降級為 defaultCuisines 渲染', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      expect(find.text('Cuisine Category'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('日式料理'), findsOneWidget);
      expect(find.text('台灣小吃'), findsOneWidget);
    });
  });
}
