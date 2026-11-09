import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_restaruant/api/dto/dto_barrel.dart';
import 'package:flutter_restaruant/domain/domain_barrel.dart';
import 'package:flutter_restaruant/flow/autocomplete/autocomplete_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockYelpAutocompleteRepository extends Mock
    implements YelpAutocompleteRepository {}

class _Data {
  static final sampleDto = YelpAutocompleteDto(
    terms: const [
      YelpAutocompleteTermDto(text: 'ramen noodle'),
    ],
    businesses: [
      YelpRestaurantSummaryDto(
        id: 'ramen-1',
        name: 'Best Ramen',
        location: const YelpRestaurantLocationDto(
          displayAddress: ['123 Main St'],
        ),
      ),
    ],
    categories: const [
      YelpRestaurantCategoryDto(alias: 'noodles', title: 'Noodles'),
    ],
  );
}

void main() {
  late _MockYelpAutocompleteRepository mockRepo;
  late AutocompleteBloc bloc;

  setUp(() async {
    await S.load(const Locale('zh', 'TW'));
    mockRepo = _MockYelpAutocompleteRepository();
    bloc = AutocompleteBloc(
      repository: mockRepo,
      debounceDuration: Duration.zero,
    );
  });

  tearDown(() {
    bloc.close();
  });

  Widget buildTestWidget({required Widget Function(BuildContext) builder}) {
    return MaterialApp(
      locale: const Locale('zh', 'TW'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Builder(builder: builder),
    );
  }

  testWidgets('RestaurantSearchDelegate shows initial guidance and search field',
      (tester) async {
    String? selectedResult;

    await tester.pumpWidget(
      buildTestWidget(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              selectedResult = await showSearch<String?>(
                context: context,
                delegate: RestaurantSearchDelegate(bloc: bloc),
              );
            },
            child: const Text('Search'),
          ),
        ),
      ),
    );

    // Tap to open search
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    // Verify search hint is displayed in the initial view
    expect(find.text('搜尋餐廳、料理或關鍵字...'), findsWidgets);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(selectedResult, isNull);
  });

  testWidgets('RestaurantSearchDelegate renders suggestions and selects term',
      (tester) async {
    final localBloc = AutocompleteBloc(
      repository: mockRepo,
      debounceDuration: Duration.zero,
    );

    when(
      () => mockRepo.autocomplete(
        'ramen',
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => _Data.sampleDto);

    String? selectedResult;

    await tester.pumpWidget(
      buildTestWidget(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              selectedResult = await showSearch<String?>(
                context: context,
                delegate: RestaurantSearchDelegate(bloc: localBloc),
              );
            },
            child: const Text('Search'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    // Enter query
    await tester.enterText(find.byType(TextField), 'ramen');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    // Verify sections rendered
    expect(find.text('熱門搜尋'), findsOneWidget);
    expect(find.text('ramen noodle'), findsOneWidget);
    expect(find.text('推薦店家'), findsOneWidget);
    expect(find.text('Best Ramen'), findsOneWidget);
    expect(find.text('相關分類'), findsOneWidget);
    expect(find.text('Noodles'), findsOneWidget);

    await tester.tap(find.text('ramen noodle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify search closed with term
    expect(selectedResult, 'ramen noodle');

    unawaited(localBloc.close());
  });

  testWidgets('RestaurantSearchDelegate clear button clears query',
      (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              await showSearch<String?>(
                context: context,
                delegate: RestaurantSearchDelegate(bloc: bloc),
              );
            },
            child: const Text('Search'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    // Enter query
    await tester.enterText(find.byType(TextField), 'test query');
    await tester.pump();

    expect(find.byKey(const Key('autocomplete_clear_button')), findsOneWidget);

    // Tap clear button
    await tester.tap(find.byKey(const Key('autocomplete_clear_button')));
    await tester.pump();

    expect(find.text('test query'), findsNothing);
  });
}
