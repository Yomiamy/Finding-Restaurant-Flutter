import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../../../domain/repositories/repositories_barrel.dart';
import '../../../manager/manager_barrel.dart';
import '../../../features/utils/utils_barrel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:equatable/equatable.dart';

part 'main_event.dart';
part 'main_state.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  static const tag = 'MainBloc';
  final MainRepository _mainRepository;

  MainBloc({required MainRepository repository})
    : _mainRepository = repository,
      super(const MainInitial()) {
    on<FetchSearchInfo>((event, emit) async {
      try {
        final Position currentPos = await Utils.getCurrentPosition();
        double lat = currentPos.latitude;
        double lng = currentPos.longitude;
        bool isLoadMore = _mainRepository.summaryInfoSet.isNotEmpty;
        int? price = event.price;
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
            .fetchYelpSearchInfo(lat, lng, price, openAt, sortBy);

        if (isLoadMore) {
          emit(LoadMoreSuccess(summaryInfos: summaryInfos));
        } else {
          emit(Success(summaryInfos: summaryInfos));
        }
      } on Exception catch (_) {
        emit(const Failure());
      }
    });

    on<Reset>((event, emit) async {
      _mainRepository.reset();
      emit(const ResetSuccess());
    });

    on<FilterListByKeyword>((event, emit) async {
      emit(const InProgress());

      final List<RestaurantEntity> filterInfos = await _mainRepository
          .filterByKeyword(event.keyword, event.sortByStr);

      if (filterInfos.isNotEmpty) {
        emit(Success(summaryInfos: filterInfos));
      } else {
        emit(const Success(summaryInfos: []));
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
}
