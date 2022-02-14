import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_restaruant/flow/favor/repository/FavorRepository.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
part 'FavorEvent.dart';
part 'FavorState.dart';

class FavorBloc extends Bloc<FavorEvent, FavorState> {

  final FavorRepository _repository;

  FavorBloc({required FavorRepository repository}) : this._repository = repository, super(FavorInitial());

  @override
  Stream<FavorState> mapEventToState(FavorEvent event) async* {
    if (event is FetchFavorInfoEvent) {
      yield* _mapFetchFavorInfoEventToState(event);
    }
  }

  Stream<FavorState> _mapFetchFavorInfoEventToState(FetchFavorInfoEvent event) async* {
    try {
      yield InProgress();

      final List<YelpRestaurantSummaryInfo> favorInfos = await this._repository.fetchFavorInfos(event.isRefreshLocalOnly);

      yield Success(favorInfos: favorInfos);
    } on Exception catch(_) {
      yield Failure();
    }
  }
}
