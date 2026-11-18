import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_restaruant/api/dto/dto_barrel.dart';
import 'package:flutter_restaruant/app/routes/routes_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/yelp_category_repository.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/features/utils/utils_barrel.dart';
import 'package:flutter_restaruant/flow/filter/filter_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_restaruant/models/model_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class _MockYelpCategoryRepository extends Mock
    implements YelpCategoryRepository {}

class _Data {
  static const List<YelpRestaurantCategoryDto> cuisines = [
    YelpRestaurantCategoryDto(alias: 'taiwanese', title: 'Taiwanese'),
    YelpRestaurantCategoryDto(alias: 'japanese', title: 'Japanese'),
    YelpRestaurantCategoryDto(alias: 'italian', title: 'Italian'),
  ];

  static const List<YelpRestaurantCategoryDto> fallbackCuisines = [
    YelpRestaurantCategoryDto(alias: 'test_fallback_1', title: 'Fallback One'),
    YelpRestaurantCategoryDto(alias: 'test_fallback_2', title: 'Fallback Two'),
  ];

  static const List<YelpRestaurantCategoryDto> routedCuisines = [
    YelpRestaurantCategoryDto(alias: 'routed_ramen', title: 'Routed Ramen'),
    YelpRestaurantCategoryDto(alias: 'routed_tacos', title: 'Routed Tacos'),
  ];
}

void main() {
  late _MockYelpCategoryRepository mockCategoryRepo;

  setUp(() {
    mockCategoryRepo = _MockYelpCategoryRepository();
    when(
      () => mockCategoryRepo.fetchCuisineCategories(
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer((_) async => _Data.cuisines);
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
                    builder: (_) => BlocProvider<FilterCuisineBloc>(
                      create: (_) => FilterCuisineBloc(
                        repository: categoryRepo ?? mockCategoryRepo,
                        logger: Logger(level: Level.off),
                      ),
                      child: const FilterPage(),
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
      await tester.scrollUntilVisible(
        find.text('Japanese'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
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

      await tester.scrollUntilVisible(
        find.text('Italian'),
        100,
        scrollable: find.byType(Scrollable).first,
      );

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

    testWidgets('菜系載入中顯示 CupertinoActivityIndicator，載入完成後渲染 Chip', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final completer = Completer<List<YelpRestaurantCategoryDto>>();
      when(
        () => mockCategoryRepo.fetchCuisineCategories(
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer((_) => completer.future);

      final arguments = Tuple2<FilterConfigs, dynamic>(FilterConfigs(), null);

      await tester.pumpWidget(buildTestApp(arguments: arguments));
      await tester.tap(find.text('Open Filter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.byType(CuisineCategoryChipsWidget), findsNothing);

      completer.complete(_Data.cuisines);
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoActivityIndicator), findsNothing);
      expect(find.text('Japanese'), findsOneWidget);
    });

    testWidgets('Repository 拋出例外時，優雅降級為 defaultCuisines 渲染', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(
        () => mockCategoryRepo.fetchCuisineCategories(
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenThrow(Exception('network down'));
      when(
        () => mockCategoryRepo.defaultCuisines,
      ).thenReturn(_Data.fallbackCuisines);

      final arguments = Tuple2<FilterConfigs, dynamic>(FilterConfigs(), null);

      await tester.pumpWidget(buildTestApp(arguments: arguments));
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Cuisine Category'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Fallback One'), findsOneWidget);
      expect(find.text('Fallback Two'), findsOneWidget);
      verify(() => mockCategoryRepo.defaultCuisines).called(1);
    });

    testWidgets('在 FilterPage 中點選菜系後，該菜系動態排列於第一列第二項並保持選取狀態', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final initialConfigs = FilterConfigs();
      final arguments = Tuple2<FilterConfigs, dynamic>(initialConfigs, null);

      await tester.pumpWidget(buildTestApp(arguments: arguments));

      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // 最初第一列第一項是 "All"，第二項是 "Taiwanese"
      final rowWidgetsBefore = tester.widgetList<Row>(
        find.descendant(
          of: find.byType(CuisineCategoryChipsWidget),
          matching: find.byType(Row),
        ),
      );
      final firstRowChipsBefore = rowWidgetsBefore.first.children
          .whereType<ChoiceChip>()
          .toList();
      expect((firstRowChipsBefore[0].label as Text).data, 'All');
      expect((firstRowChipsBefore[1].label as Text).data, 'Taiwanese');

      // 點擊 Italian
      await tester.tap(find.text('Italian'));
      await tester.pumpAndSettle();

      // 重新取得第一列
      final rowWidgetsAfter = tester.widgetList<Row>(
        find.descendant(
          of: find.byType(CuisineCategoryChipsWidget),
          matching: find.byType(Row),
        ),
      );
      final firstRowChipsAfter = rowWidgetsAfter.first.children
          .whereType<ChoiceChip>()
          .toList();
      expect((firstRowChipsAfter[0].label as Text).data, 'All');
      expect((firstRowChipsAfter[1].label as Text).data, 'Italian');
      expect(firstRowChipsAfter[1].selected, isTrue);
    });

    testWidgets('經由 routesTable 導向 FilterPage 時由 GetIt 注入 repository 並渲染菜系', (
      tester,
    ) async {
      await GetIt.I.reset();
      addTearDown(GetIt.I.reset);
      GetIt.I.registerSingleton<YelpCategoryRepository>(mockCategoryRepo);

      when(
        () => mockCategoryRepo.fetchCuisineCategories(
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer((_) async => _Data.routedCuisines);

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final arguments = Tuple2<FilterConfigs, dynamic>(FilterConfigs(), null);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeData.materialLight,
          localizationsDelegates: const [S.delegate],
          onGenerateRoute: (settings) {
            final builder = routesTable[settings.name];
            if (builder == null) return null;
            return MaterialPageRoute<dynamic>(
              builder: builder,
              settings: settings,
            );
          },
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => unawaited(
                  Navigator.of(
                    context,
                  ).pushNamed(FilterPage.routeName, arguments: arguments),
                ),
                child: const Text('Open Routed Filter'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Routed Filter'));
      await tester.pumpAndSettle();

      expect(find.byType(FilterPage), findsOneWidget);
      expect(find.text('Routed Ramen'), findsOneWidget);
      expect(find.text('Routed Tacos'), findsOneWidget);
      verify(
        () => mockCategoryRepo.fetchCuisineCategories(
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).called(1);
    });
  });
}
