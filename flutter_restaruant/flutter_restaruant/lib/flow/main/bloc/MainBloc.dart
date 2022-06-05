import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_restaruant/flow/main/repository/MainRepository.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/model/YelpSearchInfo.dart';
import 'package:flutter_restaruant/utils/Utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

part 'MainEvent.dart';
part 'MainState.dart';

class MainBloc extends Bloc<MainEvent, MainState> {

  final MainRepository _mainRepository;

  MainBloc({required MainRepository repository}) : this._mainRepository = repository, super(MainInitial()) {
    on<FetchSearchInfo>((event, emit) async {
      try {
        final Position currentPos = await Utils.getCurrentPosition();
        double lat = currentPos.latitude;
        double lng = currentPos.longitude;
        bool isLoadMore = this._mainRepository.summaryInfoSet.isNotEmpty;
        int? price = event.price;
        int? openAt = event.openAt;
        String? sortBy = event.sortBy;

        if(!isLoadMore) {
          // If it is first loading, then display loading progress.
          emit(InProgress());
        }
        final List<YelpRestaurantSummaryInfo> summaryInfos =  await this._mainRepository.fetchYelpSearchInfo(lat, lng, price, openAt, sortBy);

        if(isLoadMore) {
          emit(LoadMoreSuccess(summaryInfos: summaryInfos));
        } else {
          emit(Success(summaryInfos: summaryInfos));
        }
      } on Exception catch (_) {
        emit(Failure());
      }
    });

    on<Reset>((event, emit) async {
      this._mainRepository.reset();
      emit(ResetSuccess());
    });

    on<FilterListByKeyword>((event, emit) async {
      emit(InProgress());

      await Future.delayed(Duration(seconds: 2));
      final List<YelpRestaurantSummaryInfo> filterInfos = await this._mainRepository.filterByKeyword(event.keyword, event.sortByStr);

      if(filterInfos.isNotEmpty) {
        emit(Success(summaryInfos: filterInfos));
      } else {
        emit(Failure());
      }
    });

    on<ToggleFavor>((event, emit) async {
      try {
        emit(InProgress());

        YelpRestaurantSummaryInfo summary = event.summaryInfo;
        await this._mainRepository.toggleFavor(summary);

        emit(ToggleFavorSuccess());
      } on Exception catch(_) {
        emit(Failure());
      }
    });

    on<NotificationSetup>((event, emit) async {
      try {
        FirebaseMessaging messaging = FirebaseMessaging.instance;
        NotificationSettings settings = await messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        String? token = await messaging.getToken();
        print('User granted permission: ${settings.authorizationStatus}, token is = $token');
      } on Exception catch(_) {
        print('FCM request fail');
      }
    });
  }
}


