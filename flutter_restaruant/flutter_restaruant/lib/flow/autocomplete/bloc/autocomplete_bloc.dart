import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

import '../../../domain/repositories/yelp_autocomplete_repository.dart';
import 'autocomplete_event.dart';
import 'autocomplete_state.dart';

EventTransformer<T> _debounceRestartable<T>(Duration duration) {
  return (events, mapper) => events.debounceTime(duration).switchMap(mapper);
}

class AutocompleteBloc extends Bloc<AutocompleteEvent, AutocompleteState> {
  final YelpAutocompleteRepository _repository;
  final Logger _logger;

  static const Duration defaultDebounceDuration = Duration(milliseconds: 300);

  AutocompleteBloc({
    required YelpAutocompleteRepository repository,
    Duration debounceDuration = defaultDebounceDuration,
    Logger? logger,
  })  : _repository = repository,
        _logger = logger ?? Logger(),
        super(const AutocompleteInitial()) {
    on<AutocompleteQueryChanged>(
      _onQueryChanged,
      transformer: _debounceRestartable(debounceDuration),
    );

    on<AutocompleteCleared>((event, emit) {
      emit(const AutocompleteInitial());
    });
  }

  Future<void> _onQueryChanged(
    AutocompleteQueryChanged event,
    Emitter<AutocompleteState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const AutocompleteInitial());
      return;
    }

    emit(const AutocompleteLoading());

    try {
      final dto = await _repository.autocomplete(
        query,
        latitude: event.latitude,
        longitude: event.longitude,
      );

      final terms = dto.terms ?? [];
      final businesses = dto.businesses ?? [];
      final categories = dto.categories ?? [];

      if (terms.isEmpty && businesses.isEmpty && categories.isEmpty) {
        emit(const AutocompleteEmpty());
      } else {
        emit(
          AutocompleteSuccess(
            terms: terms,
            businesses: businesses,
            categories: categories,
          ),
        );
      }
    } on Exception catch (e, st) {
      _logger.e('Autocomplete query failed for: $query', error: e, stackTrace: st);
      emit(AutocompleteFailure(message: e.toString()));
    }
  }
}
