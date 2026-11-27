import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../domain/repositories/repositories_barrel.dart';
import 'food_maps_event.dart';
import 'food_maps_state.dart';

/// 管理共編美食地圖清單（載入、重整、建立、邀請碼加入、刪除與退出）的 BLoC。
class FoodMapsBloc extends Bloc<FoodMapsEvent, FoodMapsState> {
  final FoodMapRepository _repository;
  final Logger _logger;
  final Set<Completer<void>> _pendingRefreshCompleters = <Completer<void>>{};
  int _requestVersion = 0;
  int _feedbackNonce = 0;

  FoodMapsBloc({required FoodMapRepository repository, Logger? logger})
    : _repository = repository,
      _logger = logger ?? Logger(),
      super(const FoodMapsInitial()) {
    on<FetchFoodMaps>(_onFetch);
    on<RefreshFoodMaps>(_onRefresh);
    on<CreateFoodMapRequested>(_onCreate);
    on<JoinFoodMapByCodeRequested>(_onJoin);
    on<DeleteFoodMapRequested>(_onDelete);
    on<LeaveFoodMapRequested>(_onLeave);
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

  Future<void> _onFetch(
    FetchFoodMaps event,
    Emitter<FoodMapsState> emit,
  ) async {
    final version = ++_requestVersion;
    emit(const FoodMapsLoading());
    try {
      final maps = await _repository.fetchMyFoodMaps();
      if (version != _requestVersion) return;
      emit(FoodMapsLoaded(maps: maps, currentUid: _repository.currentUid));
    } on FoodMapException catch (e, st) {
      if (version != _requestVersion) return;
      _logger.w('FetchFoodMaps failed', error: e, stackTrace: st);
      emit(FoodMapsFailure(errorCode: e.code));
    } on Exception catch (e, st) {
      if (version != _requestVersion) return;
      _logger.e('FetchFoodMaps unexpected failure', error: e, stackTrace: st);
      emit(const FoodMapsFailure(errorCode: FoodMapErrorCode.unknown));
    }
  }

  Future<void> _onRefresh(
    RefreshFoodMaps event,
    Emitter<FoodMapsState> emit,
  ) async {
    final completer = event.completer;
    if (completer != null) {
      _pendingRefreshCompleters.add(completer);
    }
    final version = ++_requestVersion;
    try {
      final maps = await _repository.fetchMyFoodMaps();
      if (version != _requestVersion) return;
      final latest = state;
      final isSubmitting = latest is FoodMapsLoaded && latest.isSubmitting;
      emit(
        FoodMapsLoaded(
          maps: maps,
          currentUid: _repository.currentUid,
          isSubmitting: isSubmitting,
        ),
      );
    } on FoodMapException catch (e, st) {
      if (version != _requestVersion) return;
      _logger.w('RefreshFoodMaps failed', error: e, stackTrace: st);
      _emitErrorPreservingList(emit, e.code, resetSubmitting: false);
    } on Exception catch (e, st) {
      if (version != _requestVersion) return;
      _logger.e('RefreshFoodMaps unexpected failure', error: e, stackTrace: st);
      _emitErrorPreservingList(
        emit,
        FoodMapErrorCode.unknown,
        resetSubmitting: false,
      );
    } finally {
      if (completer != null) {
        _pendingRefreshCompleters.remove(completer);
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }
  }

  Future<void> _onCreate(
    CreateFoodMapRequested event,
    Emitter<FoodMapsState> emit,
  ) async {
    final current = state;
    if (current is! FoodMapsLoaded || current.isSubmitting) return;
    emit(current.copyWith(isSubmitting: true, clearFeedback: true));
    try {
      final created = await _repository.createFoodMap(
        title: event.title,
        description: event.description,
      );
      ++_requestVersion;
      final latestMaps = _latestMaps();
      final updated = [created, ...latestMaps.where((m) => m.id != created.id)];
      emit(
        FoodMapsLoaded(
          maps: updated,
          currentUid: _repository.currentUid,
          feedback: FoodMapCreatedFeedback(created, ++_feedbackNonce),
        ),
      );
    } on FoodMapException catch (e, st) {
      _logger.w('CreateFoodMap failed', error: e, stackTrace: st);
      _emitErrorPreservingList(emit, e.code);
    } on Exception catch (e, st) {
      _logger.e('CreateFoodMap unexpected failure', error: e, stackTrace: st);
      _emitErrorPreservingList(emit, FoodMapErrorCode.unknown);
    }
  }

  Future<void> _onJoin(
    JoinFoodMapByCodeRequested event,
    Emitter<FoodMapsState> emit,
  ) async {
    final current = state;
    if (current is! FoodMapsLoaded || current.isSubmitting) return;
    emit(current.copyWith(isSubmitting: true, clearFeedback: true));
    try {
      final result = await _repository.joinFoodMapByInviteCode(
        event.inviteCode,
      );
      ++_requestVersion;
      final latestMaps = _latestMaps();
      final updated = [
        result.map,
        ...latestMaps.where((m) => m.id != result.map.id),
      ];
      emit(
        FoodMapsLoaded(
          maps: updated,
          currentUid: _repository.currentUid,
          feedback: FoodMapJoinedFeedback(
            map: result.map,
            alreadyMember: result.alreadyMember,
            nonce: ++_feedbackNonce,
          ),
        ),
      );
    } on FoodMapException catch (e, st) {
      _logger.w('JoinFoodMap failed', error: e, stackTrace: st);
      _emitErrorPreservingList(emit, e.code);
    } on Exception catch (e, st) {
      _logger.e('JoinFoodMap unexpected failure', error: e, stackTrace: st);
      _emitErrorPreservingList(emit, FoodMapErrorCode.unknown);
    }
  }

  Future<void> _onDelete(
    DeleteFoodMapRequested event,
    Emitter<FoodMapsState> emit,
  ) async {
    final current = state;
    if (current is! FoodMapsLoaded || current.isSubmitting) return;
    emit(current.copyWith(isSubmitting: true, clearFeedback: true));
    try {
      await _repository.deleteFoodMap(event.mapId);
      ++_requestVersion;
      final latestMaps = _latestMaps();
      final updated = latestMaps.where((m) => m.id != event.mapId).toList();
      emit(
        FoodMapsLoaded(
          maps: updated,
          currentUid: _repository.currentUid,
          feedback: FoodMapDeletedFeedback(++_feedbackNonce),
        ),
      );
    } on FoodMapException catch (e, st) {
      _logger.w('DeleteFoodMap failed', error: e, stackTrace: st);
      _emitErrorPreservingList(emit, e.code);
    } on Exception catch (e, st) {
      _logger.e('DeleteFoodMap unexpected failure', error: e, stackTrace: st);
      _emitErrorPreservingList(emit, FoodMapErrorCode.unknown);
    }
  }

  Future<void> _onLeave(
    LeaveFoodMapRequested event,
    Emitter<FoodMapsState> emit,
  ) async {
    final current = state;
    if (current is! FoodMapsLoaded || current.isSubmitting) return;
    emit(current.copyWith(isSubmitting: true, clearFeedback: true));
    try {
      await _repository.leaveFoodMap(event.mapId);
      ++_requestVersion;
      final latestMaps = _latestMaps();
      final updated = latestMaps.where((m) => m.id != event.mapId).toList();
      emit(
        FoodMapsLoaded(
          maps: updated,
          currentUid: _repository.currentUid,
          feedback: FoodMapLeftFeedback(++_feedbackNonce),
        ),
      );
    } on FoodMapException catch (e, st) {
      _logger.w('LeaveFoodMap failed', error: e, stackTrace: st);
      _emitErrorPreservingList(emit, e.code);
    } on Exception catch (e, st) {
      _logger.e('LeaveFoodMap unexpected failure', error: e, stackTrace: st);
      _emitErrorPreservingList(emit, FoodMapErrorCode.unknown);
    }
  }

  List<FoodMapEntity> _latestMaps() {
    final latest = state;
    return latest is FoodMapsLoaded ? latest.maps : const <FoodMapEntity>[];
  }

  void _emitErrorPreservingList(
    Emitter<FoodMapsState> emit,
    FoodMapErrorCode code, {
    bool resetSubmitting = true,
  }) {
    final current = state;
    if (current is FoodMapsLoaded) {
      emit(
        current.copyWith(
          isSubmitting: resetSubmitting ? false : current.isSubmitting,
          feedback: FoodMapsActionErrorFeedback(code, ++_feedbackNonce),
        ),
      );
    } else {
      emit(FoodMapsFailure(errorCode: code));
    }
  }
}
