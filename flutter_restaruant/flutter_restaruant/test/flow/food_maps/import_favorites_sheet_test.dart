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

class _MockFavorRepository extends Mock implements FavorRepository {}

class _MockFoodMapRepository extends Mock implements FoodMapRepository {}

class _Data {
  static const RestaurantEntity existingShop = RestaurantEntity(
    id: 'r1',
    name: '已存在店',
  );

  static const RestaurantEntity newShop = RestaurantEntity(
    id: 'r2',
    name: '新最愛店',
  );
}

void main() {
  late _MockFavorRepository mockFavorRepository;
  late _MockFoodMapRepository mockFoodMapRepository;

  setUp(() {
    mockFavorRepository = _MockFavorRepository();
    mockFoodMapRepository = _MockFoodMapRepository();
  });

  testWidgets(
    'disables already-added favorites and imports newly selected ones',
    (tester) async {
      when(
        () => mockFavorRepository.fetchFavorInfos(),
      ).thenAnswer((_) async => const [_Data.existingShop, _Data.newShop]);
      when(
        () => mockFoodMapRepository.importRestaurants(
          mapId: 'm1',
          restaurants: const [_Data.newShop],
        ),
      ).thenAnswer((_) async => (addedCount: 1, skippedCount: 0));

      final bloc = ImportFavoritesBloc(
        favorRepository: mockFavorRepository,
        foodMapRepository: mockFoodMapRepository,
        logger: Logger(level: Level.off),
      );
      addTearDown(bloc.close);

      bool? sheetResult;
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
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                key: const Key('open_import_sheet_btn'),
                onPressed: () async {
                  sheetResult = await ImportFavoritesSheet.show(
                    context,
                    mapId: 'm1',
                    existingRestaurantIds: const {'r1'},
                    bloc: bloc,
                  );
                },
                child: const Text('Import'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_import_sheet_btn')));
      await tester.pumpAndSettle();

      // Existing tile is disabled & labelled
      final existingTile = tester.widget<CheckboxListTile>(
        find.byKey(const Key('import_favorite_tile_r1')),
      );
      expect(existingTile.onChanged, isNull);
      expect(
        find.text(S.current.food_maps_import_already_added),
        findsOneWidget,
      );

      // Select r2 and submit
      await tester.tap(find.byKey(const Key('import_favorite_tile_r2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import_favorites_submit_btn')));
      await tester.pumpAndSettle();

      expect(sheetResult, isTrue);
      verify(
        () => mockFoodMapRepository.importRestaurants(
          mapId: 'm1',
          restaurants: const [_Data.newShop],
        ),
      ).called(1);
    },
  );

  testWidgets(
    'shows inline error inside sheet on import failure and handles padded/empty restaurant ids',
    (tester) async {
      const paddedShop = RestaurantEntity(id: ' r3 ', name: '空白 ID 店');
      const emptyShop1 = RestaurantEntity(id: '', name: '無 ID 店 1');
      const emptyShop2 = RestaurantEntity(id: '   ', name: '無 ID 店 2');

      when(
        () => mockFavorRepository.fetchFavorInfos(),
      ).thenAnswer((_) async => const [paddedShop, emptyShop1, emptyShop2]);
      when(
        () => mockFoodMapRepository.importRestaurants(
          mapId: 'm1',
          restaurants: const [paddedShop],
        ),
      ).thenThrow(const FoodMapException(FoodMapErrorCode.permissionDenied));

      final bloc = ImportFavoritesBloc(
        favorRepository: mockFavorRepository,
        foodMapRepository: mockFoodMapRepository,
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
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                key: const Key('open_import_sheet_btn'),
                onPressed: () {
                  ImportFavoritesSheet.show(
                    context,
                    mapId: 'm1',
                    existingRestaurantIds: const {},
                    bloc: bloc,
                  );
                },
                child: const Text('Import'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_import_sheet_btn')));
      await tester.pumpAndSettle();

      // Multiple empty-ID tiles render without duplicate key exception
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('import_favorite_tile_r3')), findsOneWidget);

      await tester.tap(find.byKey(const Key('import_favorite_tile_r3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import_favorites_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(ImportFavoritesSheet), findsOneWidget);
      expect(
        find.byKey(const Key('import_favorites_error_text')),
        findsOneWidget,
      );
      expect(
        find.text(S.current.food_maps_error_permission_denied),
        findsOneWidget,
      );
    },
  );
}
