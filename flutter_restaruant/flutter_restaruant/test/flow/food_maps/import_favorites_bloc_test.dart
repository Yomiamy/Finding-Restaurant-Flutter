import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/flow/food_maps/bloc/bloc_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class _MockFavorRepository extends Mock implements FavorRepository {}

class _MockFoodMapRepository extends Mock implements FoodMapRepository {}

class _Data {
  static const List<RestaurantEntity> favorites = [
    RestaurantEntity(id: 'r1', name: '店 1'),
    RestaurantEntity(id: 'r2', name: '店 2'),
  ];
}

void main() {
  late _MockFavorRepository mockFavorRepository;
  late _MockFoodMapRepository mockFoodMapRepository;

  setUp(() async {
    await GetIt.I.reset();
    mockFavorRepository = _MockFavorRepository();
    mockFoodMapRepository = _MockFoodMapRepository();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  group('ImportFavoritesBloc', () {
    blocTest<ImportFavoritesBloc, ImportFavoritesState>(
      'fromGetIt emits unknown failure cleanly when repositories are unregistered',
      build: () =>
          ImportFavoritesBloc.fromGetIt(logger: Logger(level: Level.off)),
      act: (bloc) => bloc.add(const LoadFavoritesForImport()),
      expect: () => [
        const ImportFavoritesFailure(errorCode: FoodMapErrorCode.unknown),
      ],
    );

    blocTest<ImportFavoritesBloc, ImportFavoritesState>(
      'loads favorites and submits selected restaurants',
      build: () {
        when(
          () => mockFavorRepository.fetchFavorInfos(),
        ).thenAnswer((_) async => _Data.favorites);
        when(
          () => mockFoodMapRepository.importRestaurants(
            mapId: 'm1',
            restaurants: _Data.favorites,
          ),
        ).thenAnswer((_) async => (addedCount: 2, skippedCount: 0));
        return ImportFavoritesBloc(
          favorRepository: mockFavorRepository,
          foodMapRepository: mockFoodMapRepository,
          logger: Logger(level: Level.off),
        );
      },
      act: (bloc) async {
        bloc.add(const LoadFavoritesForImport());
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const SubmitImportFavorites(
            mapId: 'm1',
            restaurants: _Data.favorites,
          ),
        );
      },
      expect: () => [
        const ImportFavoritesLoading(),
        const ImportFavoritesReady(favorites: _Data.favorites),
        const ImportFavoritesReady(
          favorites: _Data.favorites,
          isSubmitting: true,
        ),
        const ImportFavoritesSuccess(addedCount: 2, skippedCount: 0),
      ],
    );

    blocTest<ImportFavoritesBloc, ImportFavoritesState>(
      'surfaces FoodMapException errorCode while keeping favorites list',
      build: () {
        when(
          () => mockFoodMapRepository.importRestaurants(
            mapId: 'm1',
            restaurants: _Data.favorites,
          ),
        ).thenThrow(const FoodMapException(FoodMapErrorCode.permissionDenied));
        return ImportFavoritesBloc(
          favorRepository: mockFavorRepository,
          foodMapRepository: mockFoodMapRepository,
          logger: Logger(level: Level.off),
        );
      },
      seed: () => const ImportFavoritesReady(favorites: _Data.favorites),
      act: (bloc) => bloc.add(
        const SubmitImportFavorites(mapId: 'm1', restaurants: _Data.favorites),
      ),
      expect: () => [
        const ImportFavoritesReady(
          favorites: _Data.favorites,
          isSubmitting: true,
        ),
        const ImportFavoritesReady(
          favorites: _Data.favorites,
          errorCode: FoodMapErrorCode.permissionDenied,
        ),
      ],
    );

    blocTest<ImportFavoritesBloc, ImportFavoritesState>(
      'ignores duplicate SubmitImportFavorites while isSubmitting is true',
      build: () => ImportFavoritesBloc(
        favorRepository: mockFavorRepository,
        foodMapRepository: mockFoodMapRepository,
        logger: Logger(level: Level.off),
      ),
      seed: () => const ImportFavoritesReady(
        favorites: _Data.favorites,
        isSubmitting: true,
      ),
      act: (bloc) => bloc.add(
        const SubmitImportFavorites(mapId: 'm1', restaurants: _Data.favorites),
      ),
      expect: () => <ImportFavoritesState>[],
      verify: (_) {
        verifyNever(
          () => mockFoodMapRepository.importRestaurants(
            mapId: any(named: 'mapId'),
            restaurants: any(named: 'restaurants'),
          ),
        );
      },
    );
  });
}
