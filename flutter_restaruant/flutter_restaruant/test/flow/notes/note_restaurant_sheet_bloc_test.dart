import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_restaruant/domain/domain_barrel.dart';
import 'package:flutter_restaruant/flow/notes/bloc/notes_feed_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class _MockRestaurantDetailRepository extends Mock
    implements RestaurantDetailRepository {}

class _MockFavorRepository extends Mock implements FavorRepository {}

class _Data {
  static const String restaurantId = 'biz-ichiran';

  static const RestaurantDetailEntity fullDetail = RestaurantDetailEntity(
    id: restaurantId,
    name: '一蘭拉麵 台北本店',
    rating: 4.5,
    reviewCount: 328,
    price: r'$$',
  );

  static const RestaurantDetailEntity detailWithoutId = RestaurantDetailEntity(
    id: null,
    name: '一蘭拉麵 台北本店',
    rating: 4.8,
    reviewCount: 512,
  );

  static const RestaurantDetailEntity detailSecond = RestaurantDetailEntity(
    id: 'biz-second',
    name: '第二間餐廳',
    rating: 4.9,
    reviewCount: 120,
  );
}

void main() {
  group('NoteRestaurantSheetBloc Tests', () {
    late _MockRestaurantDetailRepository mockRepository;
    late _MockFavorRepository mockFavorRepository;
    late Logger silentLogger;

    setUp(() async {
      await GetIt.I.reset();
      mockRepository = _MockRestaurantDetailRepository();
      mockFavorRepository = _MockFavorRepository();
      silentLogger = Logger(level: Level.off);
    });

    tearDown(() async {
      await GetIt.I.reset();
    });

    test(
      'initial state is NoteRestaurantSheetInitial and default timeout is 2s',
      () {
        final bloc = NoteRestaurantSheetBloc(
          repository: mockRepository,
          favorRepository: mockFavorRepository,
          logger: silentLogger,
        );
        expect(bloc.state, const NoteRestaurantSheetInitial());
        expect(
          NoteRestaurantSheetBloc.defaultFavorLookupTimeout,
          const Duration(seconds: 2),
        );
        bloc.close();
      },
    );

    test(
      'isValidRestaurantId accepts Yelp ids/aliases and rejects path or query chars',
      () {
        expect(
          NoteRestaurantSheetBloc.isValidRestaurantId('biz-ichiran'),
          isTrue,
        );
        expect(
          NoteRestaurantSheetBloc.isValidRestaurantId('WavvLdfdP6g8aZTtbBQHTw'),
          isTrue,
        );
        expect(
          NoteRestaurantSheetBloc.isValidRestaurantId('afuri_tokyo_1'),
          isTrue,
        );

        for (final badId in const <String>[
          '',
          '..',
          '../search',
          'foo/reviews',
          'biz?q=1',
          'biz#frag',
        ]) {
          expect(NoteRestaurantSheetBloc.isValidRestaurantId(badId), isFalse);
        }
      },
    );

    blocTest<NoteRestaurantSheetBloc, NoteRestaurantSheetState>(
      'emits [NoteRestaurantSheetUnlinked] when restaurantId is empty without calling repository',
      build: () => NoteRestaurantSheetBloc(
        repository: mockRepository,
        favorRepository: mockFavorRepository,
        logger: silentLogger,
      ),
      act: (bloc) =>
          bloc.add(const FetchNoteRestaurantSummary(restaurantId: '')),
      expect: () => const [NoteRestaurantSheetUnlinked()],
      verify: (_) {
        verifyNever(() => mockRepository.fetchYelpRestaurantDetailInfo(any()));
        verifyNever(() => mockFavorRepository.isFavor(any()));
      },
    );

    blocTest<NoteRestaurantSheetBloc, NoteRestaurantSheetState>(
      'emits [NoteRestaurantSheetFailure] when restaurantId is invalid without calling repository',
      build: () => NoteRestaurantSheetBloc(
        repository: mockRepository,
        favorRepository: mockFavorRepository,
        logger: silentLogger,
      ),
      act: (bloc) =>
          bloc.add(const FetchNoteRestaurantSummary(restaurantId: '../search')),
      expect: () => const [NoteRestaurantSheetFailure('Invalid restaurantId')],
      verify: (_) {
        verifyNever(() => mockRepository.fetchYelpRestaurantDetailInfo(any()));
        verifyNever(() => mockFavorRepository.isFavor(any()));
      },
    );

    blocTest<NoteRestaurantSheetBloc, NoteRestaurantSheetState>(
      'emits [NoteRestaurantSheetFailure] when repository is null',
      build: () => NoteRestaurantSheetBloc(logger: silentLogger),
      act: (bloc) => bloc.add(
        const FetchNoteRestaurantSummary(restaurantId: _Data.restaurantId),
      ),
      expect: () => const [
        NoteRestaurantSheetFailure(
          'RestaurantDetailRepository is not available',
        ),
      ],
    );

    blocTest<NoteRestaurantSheetBloc, NoteRestaurantSheetState>(
      'emits [NoteRestaurantSheetLoading, NoteRestaurantSheetLoaded] with isFavor: true',
      build: () {
        when(
          () =>
              mockRepository.fetchYelpRestaurantDetailInfo(_Data.restaurantId),
        ).thenAnswer((_) async => _Data.fullDetail);
        when(
          () => mockFavorRepository.isFavor(_Data.restaurantId),
        ).thenAnswer((_) async => true);

        return NoteRestaurantSheetBloc(
          repository: mockRepository,
          favorRepository: mockFavorRepository,
          logger: silentLogger,
        );
      },
      act: (bloc) => bloc.add(
        const FetchNoteRestaurantSummary(restaurantId: _Data.restaurantId),
      ),
      expect: () => const [
        NoteRestaurantSheetLoading(),
        NoteRestaurantSheetLoaded(detail: _Data.fullDetail, isFavor: true),
      ],
      verify: (_) {
        verify(
          () =>
              mockRepository.fetchYelpRestaurantDetailInfo(_Data.restaurantId),
        ).called(1);
        verify(() => mockFavorRepository.isFavor(_Data.restaurantId)).called(1);
      },
    );

    blocTest<NoteRestaurantSheetBloc, NoteRestaurantSheetState>(
      'emits [NoteRestaurantSheetLoading, NoteRestaurantSheetLoaded] with isFavor: false when favorRepository is null',
      build: () {
        when(
          () =>
              mockRepository.fetchYelpRestaurantDetailInfo(_Data.restaurantId),
        ).thenAnswer((_) async => _Data.fullDetail);

        return NoteRestaurantSheetBloc(
          repository: mockRepository,
          logger: silentLogger,
        );
      },
      act: (bloc) => bloc.add(
        const FetchNoteRestaurantSummary(restaurantId: _Data.restaurantId),
      ),
      expect: () => const [
        NoteRestaurantSheetLoading(),
        NoteRestaurantSheetLoaded(detail: _Data.fullDetail, isFavor: false),
      ],
    );

    blocTest<NoteRestaurantSheetBloc, NoteRestaurantSheetState>(
      'uses event restaurantId for isFavor lookup when detail.id is null',
      build: () {
        when(
          () =>
              mockRepository.fetchYelpRestaurantDetailInfo(_Data.restaurantId),
        ).thenAnswer((_) async => _Data.detailWithoutId);
        when(
          () => mockFavorRepository.isFavor(_Data.restaurantId),
        ).thenAnswer((_) async => true);

        return NoteRestaurantSheetBloc(
          repository: mockRepository,
          favorRepository: mockFavorRepository,
          logger: silentLogger,
        );
      },
      act: (bloc) => bloc.add(
        const FetchNoteRestaurantSummary(restaurantId: _Data.restaurantId),
      ),
      expect: () => const [
        NoteRestaurantSheetLoading(),
        NoteRestaurantSheetLoaded(detail: _Data.detailWithoutId, isFavor: true),
      ],
      verify: (_) {
        verify(() => mockFavorRepository.isFavor(_Data.restaurantId)).called(1);
      },
    );

    blocTest<NoteRestaurantSheetBloc, NoteRestaurantSheetState>(
      'degrades to isFavor: false when FavorRepository throws Exception',
      build: () {
        when(
          () =>
              mockRepository.fetchYelpRestaurantDetailInfo(_Data.restaurantId),
        ).thenAnswer((_) async => _Data.fullDetail);
        when(
          () => mockFavorRepository.isFavor(_Data.restaurantId),
        ).thenAnswer((_) async => throw Exception('Firestore unavailable'));

        return NoteRestaurantSheetBloc(
          repository: mockRepository,
          favorRepository: mockFavorRepository,
          logger: silentLogger,
        );
      },
      act: (bloc) => bloc.add(
        const FetchNoteRestaurantSummary(restaurantId: _Data.restaurantId),
      ),
      expect: () => const [
        NoteRestaurantSheetLoading(),
        NoteRestaurantSheetLoaded(detail: _Data.fullDetail, isFavor: false),
      ],
    );

    blocTest<NoteRestaurantSheetBloc, NoteRestaurantSheetState>(
      'degrades to isFavor: false when favor lookup hangs past favorLookupTimeout',
      build: () {
        final favorCompleter = Completer<bool>();
        when(
          () =>
              mockRepository.fetchYelpRestaurantDetailInfo(_Data.restaurantId),
        ).thenAnswer((_) async => _Data.fullDetail);
        when(
          () => mockFavorRepository.isFavor(_Data.restaurantId),
        ).thenAnswer((_) => favorCompleter.future);

        return NoteRestaurantSheetBloc(
          repository: mockRepository,
          favorRepository: mockFavorRepository,
          favorLookupTimeout: const Duration(milliseconds: 20),
          logger: silentLogger,
        );
      },
      act: (bloc) => bloc.add(
        const FetchNoteRestaurantSummary(restaurantId: _Data.restaurantId),
      ),
      wait: const Duration(milliseconds: 50),
      expect: () => const [
        NoteRestaurantSheetLoading(),
        NoteRestaurantSheetLoaded(detail: _Data.fullDetail, isFavor: false),
      ],
    );

    blocTest<NoteRestaurantSheetBloc, NoteRestaurantSheetState>(
      'emits [NoteRestaurantSheetLoading, NoteRestaurantSheetFailure] when detail has empty id and name',
      build: () {
        when(
          () =>
              mockRepository.fetchYelpRestaurantDetailInfo(_Data.restaurantId),
        ).thenAnswer(
          (_) async => const RestaurantDetailEntity(id: ' ', name: '  '),
        );

        return NoteRestaurantSheetBloc(
          repository: mockRepository,
          logger: silentLogger,
        );
      },
      act: (bloc) => bloc.add(
        const FetchNoteRestaurantSummary(restaurantId: _Data.restaurantId),
      ),
      expect: () => const [
        NoteRestaurantSheetLoading(),
        NoteRestaurantSheetFailure('Empty restaurant detail response'),
      ],
    );

    blocTest<NoteRestaurantSheetBloc, NoteRestaurantSheetState>(
      'emits failure on Exception then loads successfully on retry event',
      build: () {
        var callCount = 0;
        when(
          () =>
              mockRepository.fetchYelpRestaurantDetailInfo(_Data.restaurantId),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            throw Exception('Network timeout');
          }
          return _Data.fullDetail;
        });

        return NoteRestaurantSheetBloc(
          repository: mockRepository,
          logger: silentLogger,
        );
      },
      act: (bloc) async {
        bloc.add(
          const FetchNoteRestaurantSummary(restaurantId: _Data.restaurantId),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const FetchNoteRestaurantSummary(restaurantId: _Data.restaurantId),
        );
      },
      expect: () => const [
        NoteRestaurantSheetLoading(),
        NoteRestaurantSheetFailure('Exception: Network timeout'),
        NoteRestaurantSheetLoading(),
        NoteRestaurantSheetLoaded(detail: _Data.fullDetail, isFavor: false),
      ],
    );

    test(
      'ignores stale response when an earlier fetch finishes after a newer one',
      () async {
        final firstCompleter = Completer<RestaurantDetailEntity>();
        final secondCompleter = Completer<RestaurantDetailEntity>();
        when(
          () => mockRepository.fetchYelpRestaurantDetailInfo('biz-first'),
        ).thenAnswer((_) => firstCompleter.future);
        when(
          () => mockRepository.fetchYelpRestaurantDetailInfo('biz-second'),
        ).thenAnswer((_) => secondCompleter.future);

        final bloc = NoteRestaurantSheetBloc(
          repository: mockRepository,
          logger: silentLogger,
        );
        addTearDown(bloc.close);

        final emitted = <NoteRestaurantSheetState>[];
        final sub = bloc.stream.listen(emitted.add);
        addTearDown(sub.cancel);

        bloc.add(const FetchNoteRestaurantSummary(restaurantId: 'biz-first'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FetchNoteRestaurantSummary(restaurantId: 'biz-second'));
        await Future<void>.delayed(Duration.zero);

        secondCompleter.complete(_Data.detailSecond);
        await Future<void>.delayed(Duration.zero);

        firstCompleter.complete(_Data.fullDetail);
        await Future<void>.delayed(Duration.zero);

        expect(emitted, const [
          NoteRestaurantSheetLoading(),
          NoteRestaurantSheetLoaded(detail: _Data.detailSecond, isFavor: false),
        ]);
      },
    );

    test(
      'fromGetIt resolves registered repositories and handles unregistered safely',
      () async {
        final emptyBloc = NoteRestaurantSheetBloc.fromGetIt(
          logger: silentLogger,
        );
        addTearDown(emptyBloc.close);

        emptyBloc.add(
          const FetchNoteRestaurantSummary(restaurantId: _Data.restaurantId),
        );
        await expectLater(
          emptyBloc.stream,
          emits(
            const NoteRestaurantSheetFailure(
              'RestaurantDetailRepository is not available',
            ),
          ),
        );

        GetIt.I.registerSingleton<RestaurantDetailRepository>(mockRepository);
        GetIt.I.registerSingleton<FavorRepository>(mockFavorRepository);
        when(
          () =>
              mockRepository.fetchYelpRestaurantDetailInfo(_Data.restaurantId),
        ).thenAnswer((_) async => _Data.fullDetail);
        when(
          () => mockFavorRepository.isFavor(_Data.restaurantId),
        ).thenAnswer((_) async => true);

        final wiredBloc = NoteRestaurantSheetBloc.fromGetIt(
          logger: silentLogger,
        );
        addTearDown(wiredBloc.close);

        wiredBloc.add(
          const FetchNoteRestaurantSummary(restaurantId: _Data.restaurantId),
        );
        await expectLater(
          wiredBloc.stream,
          emitsInOrder(const [
            NoteRestaurantSheetLoading(),
            NoteRestaurantSheetLoaded(detail: _Data.fullDetail, isFavor: true),
          ]),
        );
      },
    );
  });
}
