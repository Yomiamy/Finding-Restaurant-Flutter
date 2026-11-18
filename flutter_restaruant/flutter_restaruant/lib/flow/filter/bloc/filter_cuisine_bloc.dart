import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../domain/repositories/yelp_category_repository.dart';
import 'filter_cuisine_event.dart';
import 'filter_cuisine_state.dart';

/// 管理篩選頁餐飲菜系分類載入的 BLoC。
///
/// 載入失敗時降級為 [YelpCategoryRepository.defaultCuisines]，
/// 篩選頁永遠有可選的菜系清單，因此不設失敗狀態。
class FilterCuisineBloc extends Bloc<FilterCuisineEvent, FilterCuisineState> {
  final YelpCategoryRepository _repository;
  final Logger _logger;
  int _requestId = 0;

  FilterCuisineBloc({
    required YelpCategoryRepository repository,
    Logger? logger,
  }) : _repository = repository,
       _logger = logger ?? Logger(),
       super(const FilterCuisineInitial()) {
    on<FetchFilterCuisines>(_onFetchFilterCuisines);
  }

  Future<void> _onFetchFilterCuisines(
    FetchFilterCuisines event,
    Emitter<FilterCuisineState> emit,
  ) async {
    final requestId = ++_requestId;
    emit(const FilterCuisineLoading());
    try {
      final categories = await _repository.fetchCuisineCategories();
      if (requestId != _requestId || isClosed) return;
      emit(FilterCuisineLoaded(categories: categories));
    } on Exception catch (e, st) {
      if (requestId != _requestId || isClosed) return;
      _logger.w(
        'FetchFilterCuisines failed, fallback to defaultCuisines',
        error: e,
        stackTrace: st,
      );
      emit(FilterCuisineLoaded(categories: _repository.defaultCuisines));
    }
  }
}
