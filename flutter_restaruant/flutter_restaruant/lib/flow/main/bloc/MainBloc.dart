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
    } else if(event is Reset) {
      yield* _mapResetToState();
    }  else if(event is FilterListByKeyword) {
      yield* _mapFilterListByKeywordToState(event);
    }
  }

  Stream<MainState> _mapFilterListByKeywordToState(FilterListByKeyword event) async* {
    yield InProgress();

    await Future.delayed(Duration(seconds: 2));

    final List<YelpRestaurantSummaryInfo> filterInfos = await this._mainRepository.filterByKeyword(event.keyword, event.sortByStr);
    yield (filterInfos.isNotEmpty) ? Success(summaryInfos: filterInfos) : Failure();
  }

  Stream<MainState> _mapResetToState() async* {
    this._mainRepository.reset();
    yield ResetSuccess();
  }

  Stream<MainState> _mapFetchSearchInfoToState(FetchSearchInfo event, MainState state) async* {
    try {
      final Position currentPos = await Geolocator.getCurrentPosition();
      double lat = currentPos.latitude;
      double lng = currentPos.longitude;
      bool isLoadMore = this._mainRepository.summaryInfoSet.isNotEmpty;
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


