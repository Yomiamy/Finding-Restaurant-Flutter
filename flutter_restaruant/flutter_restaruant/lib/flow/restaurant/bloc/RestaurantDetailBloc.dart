import 'package:bloc/bloc.dart';
import 'package:flutter_restaruant/api/GoogleApiUtil.dart';
import 'package:flutter_restaruant/flow/restaurant/repository/RestaurantDetailRepository.dart';
import 'package:flutter_restaruant/model/YelpRestaurantDetailInfo.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/model/YelpReviewInfo.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

part 'RestaurantDetailEvent.dart';

part 'RestaurantDetailState.dart';

class RestaurantDetailBloc
    extends Bloc<RestaurantDetailEvent, RestaurantDetailState> {
  final RestaurantDetailRepository _detailRepository;

  RestaurantDetailBloc({required RestaurantDetailRepository repository})
      : this._detailRepository = repository,
        super(RestaurantDetailInitial()) {
    on<FetchDetailInfo>((event, emit) async {
      try {
        emit(InProgress());

        final YelpRestaurantDetailInfo detailInfo = await this
            ._detailRepository
            .fetchYelpRestaurantDetailInfo(event.id);
        final YelpReviewInfo reviewInfo = await this
            ._detailRepository
            .fetchYelpRestaurantReviewInfo(event.id);

        double lat = detailInfo.coordinates?.latitude ?? 0;
        double lng = detailInfo.coordinates?.longitude ?? 0;
        final String staticMapUrl =
            GoogleApiUtil.createStaticMapUrl(lat: lat, lng: lng);

        emit(Success(
            detailInfo: detailInfo,
            reviewInfo: reviewInfo,
            staticMapUrl: staticMapUrl));
      } on Exception catch (_) {
        emit(Failure());
      }
    });

    on<ToggleFavor>((event, emit) async {
      try {
        emit(InProgress());

        YelpRestaurantSummaryInfo summary = event.summaryInfo;
        await this._detailRepository.toggleFavor(summary);

        emit(ToggleFavorSuccess());
      } on Exception catch (_) {
        emit(Failure());
      }
    });
  }
}
