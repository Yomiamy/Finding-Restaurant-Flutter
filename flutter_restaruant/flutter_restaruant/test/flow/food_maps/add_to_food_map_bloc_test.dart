import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/flow/food_maps/bloc/bloc_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
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
    itemCount: 0,
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

  setUpAll(() {
    registerFallbackValue(_Data.shop);
  });

  setUp(() async {
    await GetIt.I.reset();
    mockRepository = _MockFoodMapRepository();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  group('AddToFoodMapBloc', () {
    blocTest<AddToFoodMapBloc, AddToFoodMapState>(
      'fromGetIt emits unknown failure cleanly when FoodMapRepository is unregistered',
      build: () => AddToFoodMapBloc.fromGetIt(logger: Logger(level: Level.off)),
      act: (bloc) => bloc.add(const LoadMapsForAdd()),
      expect: () => [
        const AddToFoodMapFailure(errorCode: FoodMapErrorCode.unknown),
      ],
    );

    blocTest<AddToFoodMapBloc, AddToFoodMapState>(
      'loads maps and adds restaurant reporting alreadyExists=false',
      build: () {
        when(
          () => mockRepository.fetchMyFoodMaps(),
        ).thenAnswer((_) async => const [_Data.map]);
        when(
          () => mockRepository.addRestaurant(
            mapId: 'm1',
            restaurant: _Data.shop,
            note: '必吃',
          ),
        ).thenAnswer((_) async => (added: true, item: _Data.item));
        return AddToFoodMapBloc(
          repository: mockRepository,
          logger: Logger(level: Level.off),
        );
      },
      act: (bloc) async {
        bloc.add(const LoadMapsForAdd());
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const SubmitAddRestaurantToMap(
            mapId: 'm1',
            mapTitle: '拉麵地圖',
            restaurant: _Data.shop,
            note: '必吃',
          ),
        );
      },
      expect: () => [
        const AddToFoodMapLoading(),
        const AddToFoodMapReady(maps: [_Data.map]),
        const AddToFoodMapReady(maps: [_Data.map], isSubmitting: true),
        const AddToFoodMapSuccess(mapTitle: '拉麵地圖', alreadyExists: false),
      ],
    );

    blocTest<AddToFoodMapBloc, AddToFoodMapState>(
      'pre-validates overly long note before creating map to avoid orphan empty map',
      build: () => AddToFoodMapBloc(
        repository: mockRepository,
        logger: Logger(level: Level.off),
      ),
      seed: () => const AddToFoodMapReady(maps: []),
      act: (bloc) => bloc.add(
        CreateMapAndAddRestaurant(
          title: '新地圖',
          restaurant: _Data.shop,
          note: 'x' * 141,
        ),
      ),
      expect: () => [
        const AddToFoodMapReady(
          maps: [],
          errorCode: FoodMapErrorCode.invalidInput,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => mockRepository.createFoodMap(
            title: any(named: 'title'),
            description: any(named: 'description'),
          ),
        );
      },
    );

    blocTest<AddToFoodMapBloc, AddToFoodMapState>(
      'creates new map and adds restaurant on CreateMapAndAddRestaurant',
      build: () {
        when(
          () => mockRepository.createFoodMap(title: '新地圖', description: '讚'),
        ).thenAnswer((_) async => _Data.map.copyWith(title: '新地圖'));
        when(
          () => mockRepository.addRestaurant(
            mapId: 'm1',
            restaurant: _Data.shop,
            note: '必吃',
          ),
        ).thenAnswer((_) async => (added: true, item: _Data.item));
        return AddToFoodMapBloc(
          repository: mockRepository,
          logger: Logger(level: Level.off),
        );
      },
      seed: () => const AddToFoodMapReady(maps: []),
      act: (bloc) => bloc.add(
        const CreateMapAndAddRestaurant(
          title: '新地圖',
          description: '讚',
          restaurant: _Data.shop,
          note: '必吃',
        ),
      ),
      expect: () => [
        const AddToFoodMapReady(maps: [], isSubmitting: true),
        const AddToFoodMapSuccess(mapTitle: '新地圖', alreadyExists: false),
      ],
    );

    blocTest<AddToFoodMapBloc, AddToFoodMapState>(
      'retains newly created map in Ready state when addRestaurant fails after createFoodMap succeeds',
      build: () {
        when(
          () => mockRepository.createFoodMap(title: '新地圖', description: ''),
        ).thenAnswer((_) async => _Data.map.copyWith(title: '新地圖'));
        when(
          () => mockRepository.addRestaurant(
            mapId: 'm1',
            restaurant: _Data.shop,
            note: '',
          ),
        ).thenThrow(const FoodMapException(FoodMapErrorCode.unknown));
        return AddToFoodMapBloc(
          repository: mockRepository,
          logger: Logger(level: Level.off),
        );
      },
      seed: () => const AddToFoodMapReady(maps: []),
      act: (bloc) => bloc.add(
        const CreateMapAndAddRestaurant(title: '新地圖', restaurant: _Data.shop),
      ),
      expect: () => [
        const AddToFoodMapReady(maps: [], isSubmitting: true),
        AddToFoodMapReady(
          maps: [_Data.map.copyWith(title: '新地圖')],
          errorCode: FoodMapErrorCode.unknown,
        ),
      ],
    );

    blocTest<AddToFoodMapBloc, AddToFoodMapState>(
      'ignores duplicate submission while isSubmitting is true',
      build: () => AddToFoodMapBloc(
        repository: mockRepository,
        logger: Logger(level: Level.off),
      ),
      seed: () =>
          const AddToFoodMapReady(maps: [_Data.map], isSubmitting: true),
      act: (bloc) => bloc.add(
        const SubmitAddRestaurantToMap(
          mapId: 'm1',
          mapTitle: '拉麵地圖',
          restaurant: _Data.shop,
        ),
      ),
      expect: () => <AddToFoodMapState>[],
      verify: (_) {
        verifyNever(
          () => mockRepository.addRestaurant(
            mapId: any(named: 'mapId'),
            restaurant: any(named: 'restaurant'),
            note: any(named: 'note'),
          ),
        );
      },
    );
  });
}
