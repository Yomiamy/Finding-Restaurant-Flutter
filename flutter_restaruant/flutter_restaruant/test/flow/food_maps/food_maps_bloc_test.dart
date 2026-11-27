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
  static const FoodMapEntity map1 = FoodMapEntity(
    id: 'm1',
    title: '拉麵地圖',
    description: '深夜必吃',
    ownerUid: 'u1',
    ownerName: 'Alice',
    inviteCode: 'ABCD2345',
    memberUids: ['u1'],
    memberNames: {'u1': 'Alice'},
    itemCount: 2,
    createdAtMs: 100,
    updatedAtMs: 200,
  );

  static const FoodMapEntity map2 = FoodMapEntity(
    id: 'm2',
    title: '聚餐清單',
    description: '',
    ownerUid: 'u2',
    ownerName: 'Bob',
    inviteCode: 'EFGH6789',
    memberUids: ['u2', 'u1'],
    memberNames: {'u2': 'Bob', 'u1': 'Alice'},
    itemCount: 1,
    createdAtMs: 300,
    updatedAtMs: 400,
  );
}

void main() {
  late _MockFoodMapRepository mockRepository;

  setUp(() {
    mockRepository = _MockFoodMapRepository();
    when(() => mockRepository.currentUid).thenReturn('u1');
  });

  FoodMapsBloc buildBloc() => FoodMapsBloc(
    repository: mockRepository,
    logger: Logger(level: Level.off),
  );

  group('FoodMapsBloc', () {
    blocTest<FoodMapsBloc, FoodMapsState>(
      'emits Loading then Loaded on FetchFoodMaps success',
      build: () {
        when(
          () => mockRepository.fetchMyFoodMaps(),
        ).thenAnswer((_) async => const [_Data.map1]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const FetchFoodMaps()),
      expect: () => [
        const FoodMapsLoading(),
        const FoodMapsLoaded(maps: [_Data.map1], currentUid: 'u1'),
      ],
    );

    blocTest<FoodMapsBloc, FoodMapsState>(
      'maps unexpected Exception to FoodMapErrorCode.unknown on fetch',
      build: () {
        when(
          () => mockRepository.fetchMyFoodMaps(),
        ).thenThrow(Exception('network down'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const FetchFoodMaps()),
      expect: () => [
        const FoodMapsLoading(),
        const FoodMapsFailure(errorCode: FoodMapErrorCode.unknown),
      ],
    );

    blocTest<FoodMapsBloc, FoodMapsState>(
      'creates map and prepends with created feedback',
      build: () {
        when(
          () =>
              mockRepository.createFoodMap(title: '拉麵地圖', description: '深夜必吃'),
        ).thenAnswer((_) async => _Data.map1);
        return buildBloc();
      },
      seed: () => const FoodMapsLoaded(maps: [], currentUid: 'u1'),
      act: (bloc) => bloc.add(
        const CreateFoodMapRequested(title: '拉麵地圖', description: '深夜必吃'),
      ),
      expect: () => [
        const FoodMapsLoaded(maps: [], currentUid: 'u1', isSubmitting: true),
        const FoodMapsLoaded(
          maps: [_Data.map1],
          currentUid: 'u1',
          feedback: FoodMapCreatedFeedback(_Data.map1, 1),
        ),
      ],
    );

    blocTest<FoodMapsBloc, FoodMapsState>(
      'joins map by invite code and emits FoodMapJoinedFeedback',
      build: () {
        when(
          () => mockRepository.joinFoodMapByInviteCode('EFGH6789'),
        ).thenAnswer((_) async => (map: _Data.map2, alreadyMember: false));
        return buildBloc();
      },
      seed: () => const FoodMapsLoaded(maps: [_Data.map1], currentUid: 'u1'),
      act: (bloc) =>
          bloc.add(const JoinFoodMapByCodeRequested(inviteCode: 'EFGH6789')),
      expect: () => [
        const FoodMapsLoaded(
          maps: [_Data.map1],
          currentUid: 'u1',
          isSubmitting: true,
        ),
        const FoodMapsLoaded(
          maps: [_Data.map2, _Data.map1],
          currentUid: 'u1',
          feedback: FoodMapJoinedFeedback(
            map: _Data.map2,
            alreadyMember: false,
            nonce: 1,
          ),
        ),
      ],
    );

    blocTest<FoodMapsBloc, FoodMapsState>(
      'deletes and leaves maps preserving remaining items',
      build: () {
        when(() => mockRepository.deleteFoodMap('m1')).thenAnswer((_) async {});
        when(() => mockRepository.leaveFoodMap('m2')).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => const FoodMapsLoaded(
        maps: [_Data.map1, _Data.map2],
        currentUid: 'u1',
      ),
      act: (bloc) async {
        bloc.add(const DeleteFoodMapRequested(mapId: 'm1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const LeaveFoodMapRequested(mapId: 'm2'));
      },
      expect: () => [
        const FoodMapsLoaded(
          maps: [_Data.map1, _Data.map2],
          currentUid: 'u1',
          isSubmitting: true,
        ),
        const FoodMapsLoaded(
          maps: [_Data.map2],
          currentUid: 'u1',
          feedback: FoodMapDeletedFeedback(1),
        ),
        const FoodMapsLoaded(
          maps: [_Data.map2],
          currentUid: 'u1',
          isSubmitting: true,
        ),
        const FoodMapsLoaded(
          maps: [],
          currentUid: 'u1',
          feedback: FoodMapLeftFeedback(2),
        ),
      ],
    );

    test(
      'completes RefreshFoodMaps completer on success, failure, and close',
      () async {
        // Success case
        when(
          () => mockRepository.fetchMyFoodMaps(),
        ).thenAnswer((_) async => const [_Data.map1]);
        final okBloc = buildBloc();
        final okCompleter = Completer<void>();
        okBloc.add(RefreshFoodMaps(completer: okCompleter));
        await okCompleter.future;
        expect(okCompleter.isCompleted, isTrue);
        expect(okBloc.state, isA<FoodMapsLoaded>());
        await okBloc.close();

        // Failure case
        when(
          () => mockRepository.fetchMyFoodMaps(),
        ).thenThrow(const FoodMapException(FoodMapErrorCode.permissionDenied));
        final failBloc = buildBloc();
        final failCompleter = Completer<void>();
        failBloc.add(RefreshFoodMaps(completer: failCompleter));
        await failCompleter.future;
        expect(failCompleter.isCompleted, isTrue);
        await failBloc.close();

        // Close while pending case
        final pendingFetch = Completer<List<FoodMapEntity>>();
        when(
          () => mockRepository.fetchMyFoodMaps(),
        ).thenAnswer((_) => pendingFetch.future);
        final closeBloc = buildBloc();
        final refreshCompleter = Completer<void>();
        closeBloc.add(RefreshFoodMaps(completer: refreshCompleter));
        await Future<void>.delayed(Duration.zero);
        await closeBloc.close();
        expect(refreshCompleter.isCompleted, isTrue);
      },
    );

    test(
      'ignores re-entrant create while isSubmitting and merges against latest refreshed state',
      () async {
        final createCompleter = Completer<FoodMapEntity>();
        when(
          () => mockRepository.createFoodMap(title: '新圖', description: ''),
        ).thenAnswer((_) => createCompleter.future);
        when(
          () => mockRepository.fetchMyFoodMaps(),
        ).thenAnswer((_) async => const [_Data.map2]);

        final bloc = buildBloc()
          ..emit(const FoodMapsLoaded(maps: [_Data.map1], currentUid: 'u1'));

        bloc.add(const CreateFoodMapRequested(title: '新圖'));
        bloc.add(const CreateFoodMapRequested(title: '新圖'));
        await Future<void>.delayed(Duration.zero);

        // Concurrent refresh finishes before create completes
        final refreshCompleter = Completer<void>();
        bloc.add(RefreshFoodMaps(completer: refreshCompleter));
        await refreshCompleter.future;

        createCompleter.complete(_Data.map1.copyWith(id: 'm3', title: '新圖'));
        await Future<void>.delayed(Duration.zero);

        final loaded = bloc.state as FoodMapsLoaded;
        expect(loaded.maps.map((m) => m.id), ['m3', 'm2']);
        verify(
          () => mockRepository.createFoodMap(title: '新圖', description: ''),
        ).called(1);
        await bloc.close();
      },
    );

    blocTest<FoodMapsBloc, FoodMapsState>(
      'preserves loaded list and resets isSubmitting when write fails',
      build: () {
        when(
          () => mockRepository.deleteFoodMap('m1'),
        ).thenThrow(const FoodMapException(FoodMapErrorCode.permissionDenied));
        return buildBloc();
      },
      seed: () => const FoodMapsLoaded(maps: [_Data.map1], currentUid: 'u1'),
      act: (bloc) => bloc.add(const DeleteFoodMapRequested(mapId: 'm1')),
      expect: () => [
        const FoodMapsLoaded(
          maps: [_Data.map1],
          currentUid: 'u1',
          isSubmitting: true,
        ),
        const FoodMapsLoaded(
          maps: [_Data.map1],
          currentUid: 'u1',
          isSubmitting: false,
          feedback: FoodMapsActionErrorFeedback(
            FoodMapErrorCode.permissionDenied,
            1,
          ),
        ),
      ],
    );

    test(
      'concurrent refresh failure preserves isSubmitting and stale refresh does not overwrite fresh write',
      () async {
        // 1. Concurrent refresh failure must NOT unlock isSubmitting during an in-flight write
        final deleteCompleter = Completer<void>();
        when(
          () => mockRepository.deleteFoodMap('m1'),
        ).thenAnswer((_) => deleteCompleter.future);
        when(
          () => mockRepository.fetchMyFoodMaps(),
        ).thenThrow(Exception('transient network'));

        final bloc = buildBloc()
          ..emit(
            const FoodMapsLoaded(
              maps: [_Data.map1, _Data.map2],
              currentUid: 'u1',
            ),
          );

        bloc.add(const DeleteFoodMapRequested(mapId: 'm1'));
        await Future<void>.delayed(Duration.zero);

        final failRefresh = Completer<void>();
        bloc.add(RefreshFoodMaps(completer: failRefresh));
        await failRefresh.future;

        final midState = bloc.state as FoodMapsLoaded;
        expect(midState.isSubmitting, isTrue);
        expect(midState.feedback, isA<FoodMapsActionErrorFeedback>());

        // Re-entrant write must still be blocked
        bloc.add(const LeaveFoodMapRequested(mapId: 'm2'));
        await Future<void>.delayed(Duration.zero);
        verifyNever(() => mockRepository.leaveFoodMap(any()));

        deleteCompleter.complete();
        await Future<void>.delayed(Duration.zero);
        await bloc.close();

        // 2. Stale refresh started before write must NOT overwrite fresh write result
        final staleRefreshFetch = Completer<List<FoodMapEntity>>();
        when(
          () => mockRepository.fetchMyFoodMaps(),
        ).thenAnswer((_) => staleRefreshFetch.future);
        when(() => mockRepository.deleteFoodMap('m1')).thenAnswer((_) async {});

        final bloc2 = buildBloc()
          ..emit(
            const FoodMapsLoaded(
              maps: [_Data.map1, _Data.map2],
              currentUid: 'u1',
            ),
          );

        final staleCompleter = Completer<void>();
        bloc2.add(RefreshFoodMaps(completer: staleCompleter));
        await Future<void>.delayed(Duration.zero);

        bloc2.add(const DeleteFoodMapRequested(mapId: 'm1'));
        await Future<void>.delayed(Duration.zero);

        // Stale refresh returns old list [m1, m2] AFTER delete succeeded
        staleRefreshFetch.complete(const [_Data.map1, _Data.map2]);
        await staleCompleter.future;
        await Future<void>.delayed(Duration.zero);

        final finalState = bloc2.state as FoodMapsLoaded;
        expect(finalState.maps.map((m) => m.id), ['m2']);
        await bloc2.close();
      },
    );

    test(
      'ignores create/join while initial FetchFoodMaps is in flight so loaded maps are never wiped',
      () async {
        final fetchCompleter = Completer<List<FoodMapEntity>>();
        when(
          () => mockRepository.fetchMyFoodMaps(),
        ).thenAnswer((_) => fetchCompleter.future);

        final bloc = buildBloc();
        bloc.add(const FetchFoodMaps());
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state, const FoodMapsLoading());

        bloc.add(const CreateFoodMapRequested(title: '偷跑建立'));
        bloc.add(const JoinFoodMapByCodeRequested(inviteCode: 'ABCD2345'));
        await Future<void>.delayed(Duration.zero);

        verifyNever(
          () => mockRepository.createFoodMap(
            title: any(named: 'title'),
            description: any(named: 'description'),
          ),
        );
        verifyNever(() => mockRepository.joinFoodMapByInviteCode(any()));

        fetchCompleter.complete(const [_Data.map1, _Data.map2]);
        await Future<void>.delayed(Duration.zero);

        expect(
          bloc.state,
          const FoodMapsLoaded(
            maps: [_Data.map1, _Data.map2],
            currentUid: 'u1',
          ),
        );
        await bloc.close();
      },
    );
  });
}
