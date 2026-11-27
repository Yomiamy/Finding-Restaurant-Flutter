import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/features/utils/utils_barrel.dart';
import 'package:flutter_restaruant/flow/food_maps/food_maps_barrel.dart';
import 'package:flutter_restaruant/flow/restaurant/view/view_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class _MockFoodMapRepository extends Mock implements FoodMapRepository {}

class _Data {
  static const FoodMapEntity map = FoodMapEntity(
    id: 'm1',
    title: '拉麵地圖',
    description: '',
    ownerUid: 'u1',
    ownerName: 'Alice',
    inviteCode: 'ABCD2345',
    memberUids: ['u1', 'u2'],
    memberNames: {'u1': 'Alice', 'u2': 'Bob'},
    itemCount: 2,
    createdAtMs: 100,
    updatedAtMs: 200,
  );

  static const FoodMapItemEntity ownerItem = FoodMapItemEntity(
    restaurantId: 'r1',
    restaurant: RestaurantEntity(
      id: 'r1',
      name: '隱家拉麵',
      rating: 4.8,
      price: r'$$',
      coordinates: RestaurantCoordinatesEntity(
        latitude: 25.052,
        longitude: 121.52,
      ),
    ),
    addedByUid: 'u1',
    addedByName: 'Alice',
    note: '蒜香濃湯',
    addedAtMs: 200,
    votes: {'u1': 1},
  );

  static const FoodMapItemEntity memberItem = FoodMapItemEntity(
    restaurantId: 'r2',
    restaurant: RestaurantEntity(
      id: 'r2',
      name: '初魚鮨',
      rating: 4.9,
      coordinates: RestaurantCoordinatesEntity(
        latitude: 25.033,
        longitude: 121.564,
      ),
    ),
    addedByUid: 'u2',
    addedByName: 'Bob',
    note: '預約制',
    addedAtMs: 100,
    votes: {},
  );
}

void main() {
  late _MockFoodMapRepository mockRepository;

  setUp(() {
    mockRepository = _MockFoodMapRepository();
  });

  Widget buildApp(
    FoodMapDetailBloc bloc, {
    void Function(Object? args)? onOpenRestaurantDetail,
  }) {
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
      routes: {
        FoodMapDetailPage.routeName: (_) =>
            BlocProvider<FoodMapDetailBloc>.value(
              value: bloc,
              child: const FoodMapDetailPage(),
            ),
        RestaurantDetailPage.routeName: (context) {
          onOpenRestaurantDetail?.call(
            ModalRoute.of(context)?.settings.arguments,
          );
          return const Scaffold(body: Text('RestaurantDetailDestination'));
        },
      },
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            key: const Key('open_detail_page_btn'),
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamed(FoodMapDetailPage.routeName, arguments: _Data.map);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'renders items, enforces modify permissions, toggles vote, edits note, removes item, and navigates with Tuple2',
    (tester) async {
      // Signed in as non-owner member u2 -> can modify r2, cannot modify r1
      when(() => mockRepository.currentUid).thenReturn('u2');
      when(() => mockRepository.fetchFoodMapDetail('m1')).thenAnswer(
        (_) async =>
            (map: _Data.map, items: const [_Data.ownerItem, _Data.memberItem]),
      );
      when(
        () => mockRepository.setVote(
          mapId: 'm1',
          restaurantId: 'r1',
          vote: FoodMapVote.up,
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockRepository.updateItemNote(
          mapId: 'm1',
          restaurantId: 'r2',
          note: '超推無菜單',
        ),
      ).thenAnswer((_) async => _Data.memberItem.copyWith(note: '超推無菜單'));
      when(
        () => mockRepository.removeRestaurant(mapId: 'm1', restaurantId: 'r2'),
      ).thenAnswer((_) async {});

      Object? receivedArgs;
      final bloc = FoodMapDetailBloc(
        repository: mockRepository,
        logger: Logger(level: Level.off),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(
        buildApp(bloc, onOpenRestaurantDetail: (args) => receivedArgs = args),
      );
      await tester.tap(find.byKey(const Key('open_detail_page_btn')));
      await tester.pumpAndSettle();

      // Permission gating: u2 cannot edit/remove r1, CAN edit/remove r2
      expect(find.byKey(const Key('food_map_edit_note_r1')), findsNothing);
      expect(find.byKey(const Key('food_map_remove_r1')), findsNothing);
      expect(find.byKey(const Key('food_map_edit_note_r2')), findsOneWidget);
      expect(find.byKey(const Key('food_map_remove_r2')), findsOneWidget);

      // Upvote r1
      await tester.tap(find.byKey(const Key('food_map_upvote_r1')));
      await tester.pumpAndSettle();
      verify(
        () => mockRepository.setVote(
          mapId: 'm1',
          restaurantId: 'r1',
          vote: FoodMapVote.up,
        ),
      ).called(1);

      // Edit r2 note
      await tester.tap(find.byKey(const Key('food_map_edit_note_r2')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('food_map_edit_note_field')),
        '超推無菜單',
      );
      await tester.tap(find.byKey(const Key('food_map_edit_note_submit_btn')));
      await tester.pumpAndSettle();
      expect(find.text('超推無菜單'), findsOneWidget);

      // Remove r2
      await tester.tap(find.byKey(const Key('food_map_remove_r2')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('food_map_confirm_remove_item_btn')),
      );
      await tester.pumpAndSettle();
      expect(find.text('初魚鮨'), findsNothing);

      // Tap r1 card -> navigates to RestaurantDetailPage with Tuple2<RestaurantEntity, dynamic>
      await tester.tap(find.byKey(const Key('food_map_item_card_r1')));
      await tester.pumpAndSettle();
      expect(find.text('RestaurantDetailDestination'), findsOneWidget);
      expect(receivedArgs, isA<Tuple2<RestaurantEntity, dynamic>>());
      expect(
        (receivedArgs as Tuple2<RestaurantEntity, dynamic>).item1.id,
        'r1',
      );
    },
  );

  testWidgets('hides map view toggle on macOS (no mapMode capability)', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      when(() => mockRepository.currentUid).thenReturn('u1');
      when(() => mockRepository.fetchFoodMapDetail('m1')).thenAnswer(
        (_) async => (map: _Data.map, items: const [_Data.ownerItem]),
      );

      final bloc = FoodMapDetailBloc(
        repository: mockRepository,
        logger: Logger(level: Level.off),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(buildApp(bloc));
      await tester.tap(find.byKey(const Key('open_detail_page_btn')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('food_map_detail_toggle_view_btn')),
        findsNothing,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test(
    'FoodMapMapView.buildMarkers assigns distinct hues per member and skips missing coords',
    () async {
      await S.load(const Locale('zh', 'TW'));
      const noCoordsItem = FoodMapItemEntity(
        restaurantId: 'r3',
        restaurant: RestaurantEntity(id: 'r3', name: '無座標店'),
        addedByUid: 'u1',
        addedByName: 'Alice',
        note: '',
        addedAtMs: 50,
        votes: {},
      );

      final markers = FoodMapMapView.buildMarkers(
        items: const [_Data.ownerItem, _Data.memberItem, noCoordsItem],
        selectedIndex: 0,
        onSelect: (_) {},
      );

      expect(markers.length, 2);
      final marker1 = markers.firstWhere((m) => m.markerId.value == 'r1');
      final marker2 = markers.firstWhere((m) => m.markerId.value == 'r2');
      expect(marker1.zIndexInt, 2);
      expect(marker2.zIndexInt, 1);
      expect(marker1.icon, isNot(equals(marker2.icon)));
    },
  );

  testWidgets(
    'renders mapNotFound fallback instead of hanging when route arguments are missing',
    (tester) async {
      final bloc = FoodMapDetailBloc(
        repository: mockRepository,
        logger: Logger(level: Level.off),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh', 'TW'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          theme: AppThemeData.materialLight,
          home: BlocProvider<FoodMapDetailBloc>.value(
            value: bloc,
            child: const FoodMapDetailPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(S.current.food_maps_error_map_not_found),
        findsOneWidget,
      );
    },
  );
}
