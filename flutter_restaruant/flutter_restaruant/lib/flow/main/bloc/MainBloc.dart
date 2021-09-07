import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter_restaruant/flow/main/repository/MainRepository.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:flutter_restaruant/model/YelpSearchInfo.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

part 'MainEvent.dart';
part 'MainState.dart';

class MainBloc extends Bloc<MainEvent, MainState> {

  final MainRepository _mainRepository;

  MainBloc({required MainRepository repository}) : this._mainRepository = repository, super(MainInitial());

  @override
  Stream<MainState> mapEventToState(
    MainEvent event,
  ) async* {
    if (event is FetchSearchInfo) {
      yield* _mapFetchSearchInfoToState(event, state);
    } else if(event is ResetOffset) {
      await _mapResetOffsetToState();
    }
  }

  Future<MainState> _mapResetOffsetToState() async {
    this._mainRepository.resetOffset();
    return ResetOffsetSuccess();
  }

  Stream<MainState> _mapFetchSearchInfoToState(FetchSearchInfo event, MainState state) async* {
    try {
      final Position currentPos = await Geolocator.getCurrentPosition();
      double lat = currentPos.latitude;
      double lng = currentPos.longitude;
      bool isLoadMore = this._mainRepository.summaryInfos.isNotEmpty;
      int? price = event.price;
      int? openAt = event.openAt;
      String? sortBy = event.sortBy;

      if(!isLoadMore) {
        // If it is first loading, then display loading progress.
        yield InProgress();
      }
      final List<YelpRestaurantSummaryInfo> summaryInfos =  await this._mainRepository.fetchYelpSearchInfo(lat, lng, price, openAt, sortBy);

      yield isLoadMore ? LoadMoreSuccess(summaryInfos: summaryInfos) : Success(summaryInfos: summaryInfos);
    } on Exception catch (_) {
      yield Failure();
    }
  }
}


