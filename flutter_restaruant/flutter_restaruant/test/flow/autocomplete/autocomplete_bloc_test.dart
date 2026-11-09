import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_restaruant/api/dto/dto_barrel.dart';
import 'package:flutter_restaruant/domain/domain_barrel.dart';
import 'package:flutter_restaruant/flow/autocomplete/bloc/autocomplete_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockYelpAutocompleteRepository extends Mock
    implements YelpAutocompleteRepository {}

class _Data {
  static final sampleDto = YelpAutocompleteDto(
    terms: const [
      YelpAutocompleteTermDto(text: 'ramen'),
      YelpAutocompleteTermDto(text: 'sushi'),
    ],
    businesses: [YelpRestaurantSummaryDto(id: 'biz-1', name: 'Ichiran Ramen')],
    categories: const [
      YelpRestaurantCategoryDto(alias: 'japanese', title: 'Japanese'),
    ],
  );

  static const emptyDto = YelpAutocompleteDto(
    terms: [],
    businesses: [],
    categories: [],
  );
}

void main() {
  group('AutocompleteBloc Tests', () {
    late _MockYelpAutocompleteRepository mockRepo;

    setUp(() {
      mockRepo = _MockYelpAutocompleteRepository();
    });

    test('initial state is AutocompleteInitial', () {
      final bloc = AutocompleteBloc(repository: mockRepo);
      expect(bloc.state, const AutocompleteInitial());
      bloc.close();
    });

    blocTest<AutocompleteBloc, AutocompleteState>(
      'emits [AutocompleteInitial] when query is whitespace',
      build: () => AutocompleteBloc(
        repository: mockRepo,
        debounceDuration: Duration.zero,
      ),
      act: (bloc) => bloc.add(const AutocompleteQueryChanged('   ')),
      expect: () => [const AutocompleteInitial()],
      verify: (_) {
        verifyZeroInteractions(mockRepo);
      },
    );

    blocTest<AutocompleteBloc, AutocompleteState>(
      'emits [AutocompleteLoading, AutocompleteSuccess] on successful query',
      build: () {
        when(
          () => mockRepo.autocomplete(
            'ramen',
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => _Data.sampleDto);
        return AutocompleteBloc(
          repository: mockRepo,
          debounceDuration: Duration.zero,
        );
      },
      act: (bloc) => bloc.add(const AutocompleteQueryChanged('ramen')),
      expect: () => [
        const AutocompleteLoading(),
        AutocompleteSuccess(
          terms: const [
            YelpAutocompleteTermDto(text: 'ramen'),
            YelpAutocompleteTermDto(text: 'sushi'),
          ],
          businesses: [
            YelpRestaurantSummaryDto(id: 'biz-1', name: 'Ichiran Ramen'),
          ],
          categories: const [
            YelpRestaurantCategoryDto(alias: 'japanese', title: 'Japanese'),
          ],
        ),
      ],
      verify: (_) {
        verify(
          () => mockRepo.autocomplete('ramen', latitude: null, longitude: null),
        ).called(1);
      },
    );

    blocTest<AutocompleteBloc, AutocompleteState>(
      'emits [AutocompleteLoading, AutocompleteEmpty] when no results returned',
      build: () {
        when(
          () => mockRepo.autocomplete(
            'xyz123',
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => _Data.emptyDto);
        return AutocompleteBloc(
          repository: mockRepo,
          debounceDuration: Duration.zero,
        );
      },
      act: (bloc) => bloc.add(const AutocompleteQueryChanged('xyz123')),
      expect: () => [const AutocompleteLoading(), const AutocompleteEmpty()],
    );

    blocTest<AutocompleteBloc, AutocompleteState>(
      'emits [AutocompleteLoading, AutocompleteFailure] when repository throws Exception',
      build: () {
        when(
          () => mockRepo.autocomplete(
            'error_query',
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenThrow(Exception('Network timeout'));
        return AutocompleteBloc(
          repository: mockRepo,
          debounceDuration: Duration.zero,
        );
      },
      act: (bloc) => bloc.add(const AutocompleteQueryChanged('error_query')),
      expect: () => [
        const AutocompleteLoading(),
        const AutocompleteFailure(message: 'Exception: Network timeout'),
      ],
    );

    blocTest<AutocompleteBloc, AutocompleteState>(
      'emits [AutocompleteInitial] when AutocompleteCleared is dispatched',
      build: () => AutocompleteBloc(
        repository: mockRepo,
        debounceDuration: Duration.zero,
      ),
      seed: () => const AutocompleteSuccess(
        terms: [YelpAutocompleteTermDto(text: 'ramen')],
      ),
      act: (bloc) => bloc.add(const AutocompleteCleared()),
      expect: () => [const AutocompleteInitial()],
    );

    blocTest<AutocompleteBloc, AutocompleteState>(
      'debounces rapid query events and only executes the last one',
      build: () {
        when(
          () => mockRepo.autocomplete(
            'final',
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => _Data.sampleDto);
        return AutocompleteBloc(
          repository: mockRepo,
          debounceDuration: const Duration(milliseconds: 100),
        );
      },
      act: (bloc) async {
        bloc.add(const AutocompleteQueryChanged('f'));
        await Future.delayed(const Duration(milliseconds: 30));
        bloc.add(const AutocompleteQueryChanged('fi'));
        await Future.delayed(const Duration(milliseconds: 30));
        bloc.add(const AutocompleteQueryChanged('fin'));
        await Future.delayed(const Duration(milliseconds: 30));
        bloc.add(const AutocompleteQueryChanged('final'));
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [const AutocompleteLoading(), isA<AutocompleteSuccess>()],
      verify: (_) {
        verifyNever(
          () => mockRepo.autocomplete('f', latitude: null, longitude: null),
        );
        verifyNever(
          () => mockRepo.autocomplete('fi', latitude: null, longitude: null),
        );
        verifyNever(
          () => mockRepo.autocomplete('fin', latitude: null, longitude: null),
        );
        verify(
          () => mockRepo.autocomplete('final', latitude: null, longitude: null),
        ).called(1);
      },
    );

    blocTest<AutocompleteBloc, AutocompleteState>(
      'cancels pending debounced query when AutocompleteCleared arrives',
      build: () {
        when(
          () => mockRepo.autocomplete(
            any(),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        ).thenAnswer((_) async => _Data.sampleDto);
        return AutocompleteBloc(
          repository: mockRepo,
          debounceDuration: const Duration(milliseconds: 100),
        );
      },
      act: (bloc) async {
        bloc.add(const AutocompleteQueryChanged('ramen'));
        await Future.delayed(const Duration(milliseconds: 30));
        bloc.add(const AutocompleteCleared());
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [const AutocompleteInitial()],
      verify: (_) {
        verifyNever(
          () => mockRepo.autocomplete(
            any(),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
          ),
        );
      },
    );
  });
}
