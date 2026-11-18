import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_restaruant/api/dto/dto_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/yelp_category_repository.dart';
import 'package:flutter_restaruant/flow/filter/bloc/bloc_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class _MockYelpCategoryRepository extends Mock
    implements YelpCategoryRepository {}

class _Data {
  static const cuisines = [
    YelpRestaurantCategoryDto(alias: 'taiwanese', title: 'Taiwanese'),
    YelpRestaurantCategoryDto(alias: 'japanese', title: 'Japanese'),
  ];

  static const defaultCuisines = [
    YelpRestaurantCategoryDto(alias: 'italian', title: '義式料理'),
  ];
}

void main() {
  group('FilterCuisineBloc Tests', () {
    late _MockYelpCategoryRepository mockRepo;
    final silentLogger = Logger(level: Level.off);

    setUp(() {
      mockRepo = _MockYelpCategoryRepository();
    });

    test('initial state is FilterCuisineInitial', () {
      final bloc = FilterCuisineBloc(
        repository: mockRepo,
        logger: silentLogger,
      );
      expect(bloc.state, const FilterCuisineInitial());
      bloc.close();
    });

    blocTest<FilterCuisineBloc, FilterCuisineState>(
      'emits [FilterCuisineLoading, FilterCuisineLoaded] when repository returns cuisines',
      build: () {
        when(
          () => mockRepo.fetchCuisineCategories(),
        ).thenAnswer((_) async => _Data.cuisines);
        return FilterCuisineBloc(repository: mockRepo, logger: silentLogger);
      },
      act: (bloc) => bloc.add(const FetchFilterCuisines()),
      expect: () => const [
        FilterCuisineLoading(),
        FilterCuisineLoaded(categories: _Data.cuisines),
      ],
      verify: (_) {
        verify(() => mockRepo.fetchCuisineCategories()).called(1);
        verifyNever(() => mockRepo.defaultCuisines);
      },
    );

    blocTest<FilterCuisineBloc, FilterCuisineState>(
      'falls back to repository defaultCuisines when fetch throws Exception',
      build: () {
        when(
          () => mockRepo.fetchCuisineCategories(),
        ).thenThrow(Exception('network down'));
        when(() => mockRepo.defaultCuisines).thenReturn(_Data.defaultCuisines);
        return FilterCuisineBloc(repository: mockRepo, logger: silentLogger);
      },
      act: (bloc) => bloc.add(const FetchFilterCuisines()),
      expect: () => const [
        FilterCuisineLoading(),
        FilterCuisineLoaded(categories: _Data.defaultCuisines),
      ],
    );

    test(
      'ignores stale response when an earlier FetchFilterCuisines finishes after a newer one',
      () async {
        final firstCompleter = Completer<List<YelpRestaurantCategoryDto>>();
        final secondCompleter = Completer<List<YelpRestaurantCategoryDto>>();
        var callCount = 0;

        when(() => mockRepo.fetchCuisineCategories()).thenAnswer((_) {
          callCount++;
          return callCount == 1
              ? firstCompleter.future
              : secondCompleter.future;
        });

        final bloc = FilterCuisineBloc(
          repository: mockRepo,
          logger: silentLogger,
        );
        addTearDown(bloc.close);

        bloc
          ..add(const FetchFilterCuisines())
          ..add(const FetchFilterCuisines());

        await Future<void>.delayed(Duration.zero);

        secondCompleter.complete(_Data.cuisines);
        await Future<void>.delayed(Duration.zero);
        expect(
          bloc.state,
          const FilterCuisineLoaded(categories: _Data.cuisines),
        );

        firstCompleter.complete(_Data.defaultCuisines);
        await Future<void>.delayed(Duration.zero);
        expect(
          bloc.state,
          const FilterCuisineLoaded(categories: _Data.cuisines),
        );
      },
    );
  });
}
