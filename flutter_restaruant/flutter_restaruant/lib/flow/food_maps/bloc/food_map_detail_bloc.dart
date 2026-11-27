import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../domain/repositories/repositories_barrel.dart';
import 'food_map_detail_event.dart';
import 'food_map_detail_state.dart';

/// 管理單一共編美食地圖詳情（載入、重整、投票、短評編輯與移除餐廳）的 BLoC。
class FoodMapDetailBloc extends Bloc<FoodMapDetailEvent, FoodMapDetailState> {
  final FoodMapRepository _repository;
  final Logger _logger;
  final Set<String> _votingRestaurantIds = <String>{};
  final Set<Completer<void>> _pendingRefreshCompleters = <Completer<void>>{};
  int _requestVersion = 0;
  int _feedbackNonce = 0;

  FoodMapDetailBloc({required FoodMapRepository repository, Logger? logger})
    : _repository = repository,
      _logger = logger ?? Logger(),
      super(const FoodMapDetailInitial()) {
    on<LoadFoodMapDetail>(_onLoad);
    on<RefreshFoodMapDetail>(_onRefresh);
    on<ToggleFoodMapItemVote>(_onToggleVote);
    on<UpdateFoodMapItemNoteRequested>(_onUpdateNote);
    on<RemoveFoodMapItemRequested>(_onRemoveItem);
  }

  @override
  Future<void> close() {
    for (final completer in _pendingRefreshCompleters) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _pendingRefreshCompleters.clear();
    return super.close();
  }

  Future<void> _onLoad(
    LoadFoodMapDetail event,
    Emitter<FoodMapDetailState> emit,
  ) async {
    final version = ++_requestVersion;
    emit(FoodMapDetailLoading(initialMap: event.initialMap));
    try {
      final result = await _repository.fetchFoodMapDetail(event.mapId);
      if (version != _requestVersion) return;
      emit(
        FoodMapDetailLoaded(
          map: result.map,
          items: result.items,
          currentUid: _repository.currentUid,
        ),
      );
    } on FoodMapException catch (e, st) {
      if (version != _requestVersion) return;
      _logger.w('LoadFoodMapDetail failed', error: e, stackTrace: st);
      emit(
        FoodMapDetailFailure(initialMap: event.initialMap, errorCode: e.code),
      );
    } on Exception catch (e, st) {
      if (version != _requestVersion) return;
      _logger.e(
        'LoadFoodMapDetail unexpected failure',
        error: e,
        stackTrace: st,
      );
      emit(
        FoodMapDetailFailure(
          initialMap: event.initialMap,
          errorCode: FoodMapErrorCode.unknown,
        ),
      );
    }
  }

  Future<void> _onRefresh(
    RefreshFoodMapDetail event,
    Emitter<FoodMapDetailState> emit,
  ) async {
    final completer = event.completer;
    if (completer != null) {
      _pendingRefreshCompleters.add(completer);
    }
    final version = ++_requestVersion;
    try {
      final result = await _repository.fetchFoodMapDetail(event.mapId);
      if (version != _requestVersion) return;
      emit(
        FoodMapDetailLoaded(
          map: result.map,
          items: result.items,
          currentUid: _repository.currentUid,
        ),
      );
    } on FoodMapException catch (e, st) {
      if (version != _requestVersion) return;
      _logger.w('RefreshFoodMapDetail failed', error: e, stackTrace: st);
      _emitErrorPreservingDetail(emit, e.code);
    } on Exception catch (e, st) {
      if (version != _requestVersion) return;
      _logger.e(
        'RefreshFoodMapDetail unexpected failure',
        error: e,
        stackTrace: st,
      );
      _emitErrorPreservingDetail(emit, FoodMapErrorCode.unknown);
    } finally {
      if (completer != null) {
        _pendingRefreshCompleters.remove(completer);
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }
  }

  Future<void> _onToggleVote(
    ToggleFoodMapItemVote event,
    Emitter<FoodMapDetailState> emit,
  ) async {
    final current = state;
    if (current is! FoodMapDetailLoaded) return;
    if (!_votingRestaurantIds.add(event.restaurantId)) return;

    try {
      final targetIndex = current.items.indexWhere(
        (item) => item.restaurantId == event.restaurantId,
      );
      if (targetIndex < 0) return;

      final uid = current.currentUid;
      final existingVote = current.items[targetIndex].voteOf(uid);
      final nextVote = existingVote == event.tappedVote
          ? FoodMapVote.none
          : event.tappedVote;

      await _repository.setVote(
        mapId: event.mapId,
        restaurantId: event.restaurantId,
        vote: nextVote,
      );

      // 並發安全：一律從最新 state 套用投票變更，並遞增 _requestVersion 攔截更早發出的過期 refresh。
      ++_requestVersion;
      final latest = state;
      if (latest is! FoodMapDetailLoaded) return;
      final updatedItems = latest.items
          .map(
            (item) => item.restaurantId == event.restaurantId
                ? item.withVote(latest.currentUid, nextVote)
                : item,
          )
          .toList();
      emit(latest.copyWith(items: updatedItems, clearFeedback: true));
    } on FoodMapException catch (e, st) {
      _logger.w('ToggleFoodMapItemVote failed', error: e, stackTrace: st);
      _emitErrorPreservingDetail(emit, e.code);
    } on Exception catch (e, st) {
      _logger.e(
        'ToggleFoodMapItemVote unexpected failure',
        error: e,
        stackTrace: st,
      );
      _emitErrorPreservingDetail(emit, FoodMapErrorCode.unknown);
    } finally {
      _votingRestaurantIds.remove(event.restaurantId);
    }
  }

  Future<void> _onUpdateNote(
    UpdateFoodMapItemNoteRequested event,
    Emitter<FoodMapDetailState> emit,
  ) async {
    if (state is! FoodMapDetailLoaded) return;
    try {
      final updatedItem = await _repository.updateItemNote(
        mapId: event.mapId,
        restaurantId: event.restaurantId,
        note: event.note,
      );
      ++_requestVersion;
      final latest = state;
      if (latest is! FoodMapDetailLoaded) return;
      final updatedItems = latest.items
          .map(
            (item) =>
                item.restaurantId == event.restaurantId ? updatedItem : item,
          )
          .toList();
      emit(
        latest.copyWith(
          items: updatedItems,
          feedback: FoodMapNoteUpdatedFeedback(++_feedbackNonce),
        ),
      );
    } on FoodMapException catch (e, st) {
      _logger.w('UpdateFoodMapItemNote failed', error: e, stackTrace: st);
      _emitErrorPreservingDetail(emit, e.code);
    } on Exception catch (e, st) {
      _logger.e(
        'UpdateFoodMapItemNote unexpected failure',
        error: e,
        stackTrace: st,
      );
      _emitErrorPreservingDetail(emit, FoodMapErrorCode.unknown);
    }
  }

  Future<void> _onRemoveItem(
    RemoveFoodMapItemRequested event,
    Emitter<FoodMapDetailState> emit,
  ) async {
    if (state is! FoodMapDetailLoaded) return;
    try {
      await _repository.removeRestaurant(
        mapId: event.mapId,
        restaurantId: event.restaurantId,
      );
      ++_requestVersion;
      final latest = state;
      if (latest is! FoodMapDetailLoaded) return;
      final updatedItems = latest.items
          .where((item) => item.restaurantId != event.restaurantId)
          .toList();
      emit(
        latest.copyWith(
          map: latest.map.copyWith(itemCount: updatedItems.length),
          items: updatedItems,
          feedback: FoodMapItemRemovedFeedback(++_feedbackNonce),
        ),
      );
    } on FoodMapException catch (e, st) {
      _logger.w('RemoveFoodMapItem failed', error: e, stackTrace: st);
      _emitErrorPreservingDetail(emit, e.code);
    } on Exception catch (e, st) {
      _logger.e(
        'RemoveFoodMapItem unexpected failure',
        error: e,
        stackTrace: st,
      );
      _emitErrorPreservingDetail(emit, FoodMapErrorCode.unknown);
    }
  }

  void _emitErrorPreservingDetail(
    Emitter<FoodMapDetailState> emit,
    FoodMapErrorCode code,
  ) {
    final current = state;
    if (current is FoodMapDetailLoaded) {
      emit(
        current.copyWith(
          feedback: FoodMapDetailActionErrorFeedback(code, ++_feedbackNonce),
        ),
      );
    } else if (current is FoodMapDetailLoading) {
      emit(
        FoodMapDetailFailure(initialMap: current.initialMap, errorCode: code),
      );
    } else {
      emit(FoodMapDetailFailure(errorCode: code));
    }
  }
}
