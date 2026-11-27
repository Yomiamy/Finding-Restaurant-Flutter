import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/flow/food_maps/food_maps_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class _MockFoodMapRepository extends Mock implements FoodMapRepository {}

class _Data {
  static const RestaurantEntity shop = RestaurantEntity(id: 'r1', name: '隱家拉麵');

  static const FoodMapEntity map = FoodMapEntity(
    id: 'm1',
    title: '拉麵地圖',
    description: '',
    ownerUid: 'u1',
    ownerName: 'Alice',
    inviteCode: 'ABCD2345',
    memberUids: ['u1'],
    memberNames: {'u1': 'Alice'},
    itemCount: 1,
    createdAtMs: 100,
    updatedAtMs: 100,
  );

  static const FoodMapItemEntity item = FoodMapItemEntity(
    restaurantId: 'r1',
    restaurant: shop,
    addedByUid: 'u1',
    addedByName: 'Alice',
    note: '必吃',
    addedAtMs: 200,
    votes: {},
  );
}

void main() {
  late _MockFoodMapRepository mockRepository;

  setUp(() {
    mockRepository = _MockFoodMapRepository();
  });

  Widget buildHost(AddToFoodMapBloc bloc) {
    return MaterialApp(
      locale: const Locale('zh', 'TW'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      theme: AppThemeData.materialLight,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            key: const Key('open_add_sheet_btn'),
            onPressed: () {
              AddToFoodMapSheet.show(
                context,
                restaurant: _Data.shop,
                bloc: bloc,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'selects existing map, submits note, and closes sheet with SnackBar',
    (tester) async {
      when(
        () => mockRepository.fetchMyFoodMaps(),
      ).thenAnswer((_) async => const [_Data.map]);
      when(
        () => mockRepository.addRestaurant(
          mapId: 'm1',
          restaurant: _Data.shop,
          note: '必吃叉燒',
        ),
      ).thenAnswer((_) async => (added: true, item: _Data.item));

      final bloc = AddToFoodMapBloc(
        repository: mockRepository,
        logger: Logger(level: Level.off),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(buildHost(bloc));
      await tester.tap(find.byKey(const Key('open_add_sheet_btn')));
      await tester.pumpAndSettle();

      expect(find.text('拉麵地圖'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('add_to_food_map_note_field')),
        '必吃叉燒',
      );
      await tester.tap(find.byKey(const Key('add_to_food_map_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(AddToFoodMapSheet), findsNothing);
      expect(
        find.text(S.current.food_maps_added_success('拉麵地圖')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'auto-shows create form when user has no maps and creates + adds restaurant',
    (tester) async {
      when(() => mockRepository.fetchMyFoodMaps()).thenAnswer((_) async => []);
      when(
        () => mockRepository.createFoodMap(title: '首張地圖', description: ''),
      ).thenAnswer((_) async => _Data.map.copyWith(title: '首張地圖'));
      when(
        () => mockRepository.addRestaurant(
          mapId: 'm1',
          restaurant: _Data.shop,
          note: '',
        ),
      ).thenAnswer((_) async => (added: true, item: _Data.item));

      final bloc = AddToFoodMapBloc(
        repository: mockRepository,
        logger: Logger(level: Level.off),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(buildHost(bloc));
      await tester.tap(find.byKey(const Key('open_add_sheet_btn')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('add_to_food_map_new_title_field')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('add_to_food_map_new_title_field')),
        '首張地圖',
      );
      await tester.tap(find.byKey(const Key('add_to_food_map_submit_btn')));
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.createFoodMap(title: '首張地圖', description: ''),
      ).called(1);
      expect(find.byType(AddToFoodMapSheet), findsNothing);
    },
  );
}
