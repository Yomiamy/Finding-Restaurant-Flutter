import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../../../domain/repositories/repositories_barrel.dart';
import 'note_restaurant_sheet_event.dart';
import 'note_restaurant_sheet_state.dart';

/// 管理探店筆記餐廳標籤 BottomSheet 詳情與收藏狀態查詢的 BLoC。
class NoteRestaurantSheetBloc
    extends Bloc<NoteRestaurantSheetEvent, NoteRestaurantSheetState> {
  static const Duration defaultFavorLookupTimeout = Duration(seconds: 2);
  static final RegExp _validRestaurantIdPattern = RegExp(r'^[A-Za-z0-9_-]+$');

  final RestaurantDetailRepository? _repository;
  final FavorRepository? _favorRepository;
  final Duration _favorLookupTimeout;
  final Logger _logger;
  int _requestId = 0;

  NoteRestaurantSheetBloc({
    RestaurantDetailRepository? repository,
    FavorRepository? favorRepository,
    Duration favorLookupTimeout = defaultFavorLookupTimeout,
    Logger? logger,
  }) : _repository = repository,
       _favorRepository = favorRepository,
       _favorLookupTimeout = favorLookupTimeout,
       _logger = logger ?? Logger(),
       super(const NoteRestaurantSheetInitial()) {
    on<FetchNoteRestaurantSummary>(_onFetchSummary);
  }

  /// 從 GetIt 解析資料層依賴建立 BLoC（供未由外層注入的 BottomSheet 使用）。
  factory NoteRestaurantSheetBloc.fromGetIt({
    Duration favorLookupTimeout = defaultFavorLookupTimeout,
    Logger? logger,
  }) {
    final getIt = GetIt.I;
    return NoteRestaurantSheetBloc(
      repository: getIt.isRegistered<RestaurantDetailRepository>()
          ? getIt<RestaurantDetailRepository>()
          : null,
      favorRepository: getIt.isRegistered<FavorRepository>()
          ? getIt<FavorRepository>()
          : null,
      favorLookupTimeout: favorLookupTimeout,
      logger: logger,
    );
  }

  /// 驗證 `restaurantId` 是否只含英數、`-` 與 `_`，防止路徑跳脫或查詢字串注入。
  static bool isValidRestaurantId(String id) {
    return id.isNotEmpty && _validRestaurantIdPattern.hasMatch(id);
  }

  Future<void> _onFetchSummary(
    FetchNoteRestaurantSummary event,
    Emitter<NoteRestaurantSheetState> emit,
  ) async {
    final requestId = ++_requestId;
    final restaurantId = event.restaurantId;

    if (restaurantId.isEmpty) {
      emit(const NoteRestaurantSheetUnlinked());
      return;
    }

    if (!isValidRestaurantId(restaurantId)) {
      _logger.w('Blocked invalid restaurantId in note sheet: $restaurantId');
      emit(const NoteRestaurantSheetFailure('Invalid restaurantId'));
      return;
    }

    final repository = _repository;
    if (repository == null) {
      _logger.w(
        'RestaurantDetailRepository is not registered; cannot load $restaurantId',
      );
      emit(
        const NoteRestaurantSheetFailure(
          'RestaurantDetailRepository is not available',
        ),
      );
      return;
    }

    emit(const NoteRestaurantSheetLoading());

    try {
      final detail = await repository.fetchYelpRestaurantDetailInfo(
        restaurantId,
      );
      if (requestId != _requestId || isClosed) return;

      final detailId = detail.id?.trim() ?? '';
      final detailName = detail.name?.trim() ?? '';
      if (detailId.isEmpty && detailName.isEmpty) {
        _logger.w('Empty restaurant detail response for id=$restaurantId');
        emit(
          const NoteRestaurantSheetFailure('Empty restaurant detail response'),
        );
        return;
      }

      final favorLookupId = detailId.isNotEmpty ? detailId : restaurantId;
      final isFavor = await _resolveIsFavor(favorLookupId);
      if (requestId != _requestId || isClosed) return;

      emit(NoteRestaurantSheetLoaded(detail: detail, isFavor: isFavor));
    } on Exception catch (e, st) {
      if (requestId != _requestId || isClosed) return;
      _logger.e(
        'Failed to load restaurant detail id=$restaurantId',
        error: e,
        stackTrace: st,
      );
      emit(NoteRestaurantSheetFailure(e.toString()));
    }
  }

  Future<bool> _resolveIsFavor(String restaurantId) async {
    final favorRepository = _favorRepository;
    if (favorRepository == null || restaurantId.isEmpty) return false;
    try {
      return await favorRepository
          .isFavor(restaurantId)
          .timeout(_favorLookupTimeout);
    } on TimeoutException catch (e, st) {
      _logger.w(
        'Timeout checking favor status for restaurant=$restaurantId',
        error: e,
        stackTrace: st,
      );
      return false;
    } on Exception catch (e, st) {
      _logger.w(
        'Failed to check favor status for restaurant=$restaurantId',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }
}
