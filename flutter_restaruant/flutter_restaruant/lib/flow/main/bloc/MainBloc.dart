import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter_restaruant/flow/main/repository/MainRepository.dart';
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
    }
  }

  Stream<MainState> _mapFetchSearchInfoToState(FetchSearchInfo event, MainState state) async* {
    try {
      yield InProgress();

      final Position currentPos = await Geolocator.getCurrentPosition();
      final YelpSearchInfo searchInfo =  await this._mainRepository.fetchYelpSearchInfo(currentPos.latitude, currentPos.longitude);

      yield Success(searchInfo: searchInfo);
    } on Exception catch (_) {
      yield Failure();
    }
  }
}


