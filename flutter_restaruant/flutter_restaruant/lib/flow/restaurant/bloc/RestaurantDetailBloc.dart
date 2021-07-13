import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_restaruant/flow/restaurant/repository/RestaurantDetailRepository.dart';
import 'package:flutter_restaruant/model/YelpRestaurantDetailInfo.dart';
import 'package:flutter_restaruant/model/YelpReviewDetailInfo.dart';
import 'package:flutter_restaruant/model/YelpReviewInfo.dart';
import 'package:flutter_restaruant/model/YelpReviewerInfo.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

part 'RestaurantDetailEvent.dart';
part 'RestaurantDetailState.dart';

class RestaurantDetailBloc extends Bloc<RestaurantDetailEvent, RestaurantDetailState> {

  final RestaurantDetailRepository _detailRepository;

  RestaurantDetailBloc({required RestaurantDetailRepository repository}) : this._detailRepository = repository, super(RestaurantDetailInitial());

  @override
  Stream<RestaurantDetailState> mapEventToState(
    RestaurantDetailEvent event,
  ) async* {
    if(event is FetchDetailInfo) {
      yield* _mapFetchDetailInfoToState(event, state);
    }
  }

  Stream<RestaurantDetailState> _mapFetchDetailInfoToState(FetchDetailInfo event, RestaurantDetailState state) async* {
    try {
      yield InProgress();

      final YelpRestaurantDetailInfo detailInfo = await this._detailRepository.fetchYelpRestaurantDetailInfo(event.id);
      final YelpReviewInfo reviewInfo = await this._detailRepository.fetchYelpRestaurantReviewInfo(event.id);

      yield Success(detailInfo: detailInfo, reviewInfo: reviewInfo);
    } on Exception catch (_) {
      yield Failure();
    }
  }
}
