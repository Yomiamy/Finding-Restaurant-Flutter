import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

import '../../../domain/repositories/yelp_autocomplete_repository.dart';
import 'autocomplete_event.dart';
import 'autocomplete_state.dart';

EventTransformer<AutocompleteEvent> _debounceRestartable(Duration duration) {
  return (events, mapper) => events.switchMap((event) {
    if (event is AutocompleteQueryChanged &&
        event.query.trim().isNotEmpty &&
        duration > Duration.zero) {
      return TimerStream<AutocompleteEvent>(event, duration).switchMap(mapper);
    }
    return mapper(event);
  });
}

/// 管理餐廳搜尋即時補全與聯想建議狀態的 BLoC。
///
/// 透過 300ms 防抖與 `switchMap` 取消過期或已清除的查詢請求，並將結果分類為關鍵詞、店家與分類。
class AutocompleteBloc extends Bloc<AutocompleteEvent, AutocompleteState> {
  final YelpAutocompleteRepository _repository;
  final Logger _logger;

  static const Duration defaultDebounceDuration = Duration(milliseconds: 300);

  AutocompleteBloc({
    required YelpAutocompleteRepository repository,
    Duration debounceDuration = defaultDebounceDuration,
    Logger? logger,
  }) : _repository = repository,
       _logger = logger ?? Logger(),
       super(const AutocompleteInitial()) {
    on<AutocompleteEvent>(
      _onEvent,
      transformer: _debounceRestartable(debounceDuration),
    );
  }

  Future<void> _onEvent(
    AutocompleteEvent event,
    Emitter<AutocompleteState> emit,
  ) async {
    switch (event) {
      case AutocompleteCleared():
        emit(const AutocompleteInitial());
      case AutocompleteQueryChanged():
        await _onQueryChanged(event, emit);
    }
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
      _logger.e('Autocomplete query failed', error: e, stackTrace: st);
      emit(AutocompleteFailure(message: e.toString()));
    }
  }
}
