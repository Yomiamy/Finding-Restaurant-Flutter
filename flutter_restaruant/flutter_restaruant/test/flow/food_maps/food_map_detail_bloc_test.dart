import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/flow/food_maps/bloc/bloc_barrel.dart';
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

  static const FoodMapItemEntity itemA = FoodMapItemEntity(
    restaurantId: 'r-a',
    restaurant: RestaurantEntity(id: 'r-a', name: '店 A'),
    addedByUid: 'u1',
    addedByName: 'Alice',
    note: '原短評',
    addedAtMs: 200,
    votes: {},
  );

  static const FoodMapItemEntity itemB = FoodMapItemEntity(
    restaurantId: 'r-b',
    restaurant: RestaurantEntity(id: 'r-b', name: '店 B'),
    addedByUid: 'u2',
    addedByName: 'Bob',
    note: '',
    addedAtMs: 100,
    votes: {},
  );
}

void main() {
  late _MockFoodMapRepository mockRepository;

  setUp(() {
    mockRepository = _MockFoodMapRepository();
    when(() => mockRepository.currentUid).thenReturn('u1');
  });

  FoodMapDetailBloc buildBloc() => FoodMapDetailBloc(
    repository: mockRepository,
    logger: Logger(level: Level.off),
  );

  group('FoodMapDetailBloc', () {
    blocTest<FoodMapDetailBloc, FoodMapDetailState>(
      'loads map detail and items',
      build: () {
        when(() => mockRepository.fetchFoodMapDetail('m1')).thenAnswer(
          (_) async =>
              (map: _Data.map, items: const [_Data.itemA, _Data.itemB]),
        );
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const LoadFoodMapDetail(mapId: 'm1', initialMap: _Data.map)),
      expect: () => [
        const FoodMapDetailLoading(initialMap: _Data.map),
        const FoodMapDetailLoaded(
          map: _Data.map,
          items: [_Data.itemA, _Data.itemB],
          currentUid: 'u1',
        ),
      ],
    );

    blocTest<FoodMapDetailBloc, FoodMapDetailState>(
      'toggles vote on then clears on second tap',
      build: () {
        when(
          () => mockRepository.setVote(
            mapId: 'm1',
            restaurantId: 'r-a',
            vote: FoodMapVote.up,
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockRepository.setVote(
            mapId: 'm1',
            restaurantId: 'r-a',
            vote: FoodMapVote.none,
          ),
        ).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => const FoodMapDetailLoaded(
        map: _Data.map,
        items: [_Data.itemA],
        currentUid: 'u1',
      ),
      act: (bloc) async {
        bloc.add(
          const ToggleFoodMapItemVote(
            mapId: 'm1',
            restaurantId: 'r-a',
            tappedVote: FoodMapVote.up,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const ToggleFoodMapItemVote(
            mapId: 'm1',
            restaurantId: 'r-a',
            tappedVote: FoodMapVote.up,
          ),
        );
      },
      expect: () => [
        FoodMapDetailLoaded(
          map: _Data.map,
          items: [_Data.itemA.withVote('u1', FoodMapVote.up)],
          currentUid: 'u1',
        ),
        const FoodMapDetailLoaded(
          map: _Data.map,
          items: [_Data.itemA],
          currentUid: 'u1',
        ),
      ],
    );

    test(
      'parallel votes on different items preserve both updates without clobbering',
      () async {
        final completerA = Completer<void>();
        final completerB = Completer<void>();

        when(
          () => mockRepository.setVote(
            mapId: 'm1',
            restaurantId: 'r-a',
            vote: FoodMapVote.up,
          ),
        ).thenAnswer((_) => completerA.future);
        when(
          () => mockRepository.setVote(
            mapId: 'm1',
            restaurantId: 'r-b',
            vote: FoodMapVote.down,
          ),
        ).thenAnswer((_) => completerB.future);

        final bloc = buildBloc()
          ..emit(
            const FoodMapDetailLoaded(
              map: _Data.map,
              items: [_Data.itemA, _Data.itemB],
              currentUid: 'u1',
            ),
          );

        // Fire votes on both items concurrently AND a duplicate rapid tap on itemA
        bloc.add(
          const ToggleFoodMapItemVote(
            mapId: 'm1',
            restaurantId: 'r-a',
            tappedVote: FoodMapVote.up,
          ),
        );
        bloc.add(
          const ToggleFoodMapItemVote(
            mapId: 'm1',
            restaurantId: 'r-a',
            tappedVote: FoodMapVote.down,
          ),
        );
        bloc.add(
          const ToggleFoodMapItemVote(
            mapId: 'm1',
            restaurantId: 'r-b',
            tappedVote: FoodMapVote.down,
          ),
        );

        await Future<void>.delayed(Duration.zero);
        completerB.complete();
        await Future<void>.delayed(Duration.zero);
        completerA.complete();
        await Future<void>.delayed(Duration.zero);

        final finalState = bloc.state as FoodMapDetailLoaded;
        expect(finalState.items[0].voteOf('u1'), FoodMapVote.up);
        expect(finalState.items[1].voteOf('u1'), FoodMapVote.down);
        verifyNever(
          () => mockRepository.setVote(
            mapId: 'm1',
            restaurantId: 'r-a',
            vote: FoodMapVote.down,
          ),
        );

        await bloc.close();
      },
    );

    blocTest<FoodMapDetailBloc, FoodMapDetailState>(
      'updates item note and removes item',
      build: () {
        when(
          () => mockRepository.updateItemNote(
            mapId: 'm1',
            restaurantId: 'r-a',
            note: '新短評',
          ),
        ).thenAnswer((_) async => _Data.itemA.copyWith(note: '新短評'));
        when(
          () =>
              mockRepository.removeRestaurant(mapId: 'm1', restaurantId: 'r-a'),
        ).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => const FoodMapDetailLoaded(
        map: _Data.map,
        items: [_Data.itemA, _Data.itemB],
        currentUid: 'u1',
      ),
      act: (bloc) async {
        bloc.add(
          const UpdateFoodMapItemNoteRequested(
            mapId: 'm1',
            restaurantId: 'r-a',
            note: '新短評',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const RemoveFoodMapItemRequested(mapId: 'm1', restaurantId: 'r-a'),
        );
      },
      expect: () => [
        FoodMapDetailLoaded(
          map: _Data.map,
          items: [
            _Data.itemA.copyWith(note: '新短評'),
            _Data.itemB,
          ],
          currentUid: 'u1',
          feedback: const FoodMapNoteUpdatedFeedback(1),
        ),
        FoodMapDetailLoaded(
          map: _Data.map.copyWith(itemCount: 1),
          items: const [_Data.itemB],
          currentUid: 'u1',
          feedback: const FoodMapItemRemovedFeedback(2),
        ),
      ],
    );

    test(
      'completes RefreshFoodMapDetail completer on success, failure, and close',
      () async {
        // Success case
        when(
          () => mockRepository.fetchFoodMapDetail('m1'),
        ).thenAnswer((_) async => (map: _Data.map, items: const [_Data.itemA]));
        final okBloc = buildBloc();
        final okCompleter = Completer<void>();
        okBloc.add(RefreshFoodMapDetail(mapId: 'm1', completer: okCompleter));
        await okCompleter.future;
        expect(okCompleter.isCompleted, isTrue);
        expect(okBloc.state, isA<FoodMapDetailLoaded>());
        await okBloc.close();

        // Failure case
        when(
          () => mockRepository.fetchFoodMapDetail('m1'),
        ).thenThrow(const FoodMapException(FoodMapErrorCode.permissionDenied));
        final failBloc = buildBloc();
        final failCompleter = Completer<void>();
        failBloc.add(
          RefreshFoodMapDetail(mapId: 'm1', completer: failCompleter),
        );
        await failCompleter.future;
        expect(failCompleter.isCompleted, isTrue);
        await failBloc.close();

        // Close while pending case
        final pending =
            Completer<({FoodMapEntity map, List<FoodMapItemEntity> items})>();
        when(
          () => mockRepository.fetchFoodMapDetail('m1'),
        ).thenAnswer((_) => pending.future);

        final closeBloc = buildBloc();
        final completer = Completer<void>();
        closeBloc.add(RefreshFoodMapDetail(mapId: 'm1', completer: completer));
        await Future<void>.delayed(Duration.zero);
        await closeBloc.close();

        expect(completer.isCompleted, isTrue);
      },
    );
  });
}
