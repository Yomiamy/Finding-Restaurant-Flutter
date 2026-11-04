import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../domain/repositories/repositories_barrel.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../../features/manager/manager_barrel.dart';

part 'main_event.dart';
part 'main_state.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  static const tag = 'MainBloc';
  final _logger = Logger();
  final MainRepository _mainRepository;

  MainBloc({required MainRepository repository})
    : _mainRepository = repository,
      super(const MainInitial()) {
    on<FetchSearchInfo>((event, emit) async {
      try {
        final (:lat, :lng, :location) = await _resolveLocation(
          location: event.location,
        );

        bool isLoadMore = _mainRepository.summaryInfoSet.isNotEmpty;
        String? price = event.price;
        int? openAt = event.openAt;
        String? sortBy = event.sortBy;

        if (isLoadMore) {
          // Carry the list that is already on screen. Re-reading it from the
          // repository would resurrect keyword-filtered-out items and make the
          // list jump while the next page is still in flight.
          final MainState current = state;
          final List<RestaurantEntity> onScreen = switch (current) {
            Success(:final summaryInfos) => summaryInfos,
            LoadMoreSuccess(:final summaryInfos) => summaryInfos,
            LoadMoreInProgress(:final summaryInfos) => summaryInfos,
            _ => const <RestaurantEntity>[],
          };

          emit(LoadMoreInProgress(summaryInfos: onScreen));
        } else {
          // If it is first loading, then display loading progress.
          emit(const InProgress());
        }
        final List<RestaurantEntity> summaryInfos = await _mainRepository
            .fetchYelpSearchInfo(
              lat: lat,
              lng: lng,
              location: location,
              price: price,
              openAt: openAt,
              sortByStr: sortBy,
              term: event.term,
              categories: event.categories,
              radius: event.radius,
              openNow: event.openNow,
            );

        if (isLoadMore) {
          emit(LoadMoreSuccess(summaryInfos: summaryInfos));
        } else {
          emit(Success(summaryInfos: summaryInfos));
        }
      } on Exception catch (e, st) {
        _logger.e('FetchSearchInfo 發生異常', error: e, stackTrace: st);
        emit(const Failure());
      }
    });

    on<Reset>((event, emit) async {
      _mainRepository.reset();
      emit(const ResetSuccess());
    });

    on<FilterListByKeyword>((event, emit) async {
      try {
        emit(const InProgress());

        final (:lat, :lng, :location) = await _resolveLocation();

        final List<RestaurantEntity> summaryInfos = await _mainRepository
            .fetchYelpSearchInfo(
              lat: lat,
              lng: lng,
              location: location,
              price: event.price,
              openAt: event.openAt,
              sortByStr: event.sortByStr,
              term: event.keyword,
            );

        emit(Success(summaryInfos: summaryInfos));
      } on Exception catch (e, st) {
        _logger.e('FilterListByKeyword 發生異常', error: e, stackTrace: st);
        emit(const Failure());
      }
    });

    on<ToggleFavor>((event, emit) async {
      try {
        emit(const InProgress());

        await _mainRepository.toggleFavor(event.summaryInfo);

        emit(const ToggleFavorSuccess());
      } on Exception catch (_) {
        emit(const Failure());
      }
    });

    on<NotificationSetup>((event, emit) async {
      FcmManager fcmManager = FcmManager();

      await fcmManager.requestPermission();
      String fcmToken = await fcmManager.fcmToken;
      debugPrint('$tag, fcm Token is $fcmToken');
    });
  }

  Future<({double? lat, double? lng, String? location})> _resolveLocation({
    String? location,
  }) async {
    if (location != null && location.isNotEmpty) {
      return (lat: null, lng: null, location: location);
    }
    try {
      final Position currentPos = await Utils.getCurrentPosition();
      return (
        lat: currentPos.latitude,
        lng: currentPos.longitude,
        location: null,
      );
    } catch (_) {
      return (lat: null, lng: null, location: 'Taipei');
    }
  }
}
