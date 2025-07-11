import 'package:bloc/bloc.dart';
import 'package:flutter_restaruant/flow/favor/repository/FavorRepository.dart';
import 'package:flutter_restaruant/model/YelpRestaurantSummaryInfo.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
part 'FavorEvent.dart';
part 'FavorState.dart';

class FavorBloc extends Bloc<FavorEvent, FavorState> {
  final FavorRepository _repository;

  FavorBloc({required FavorRepository repository})
      : this._repository = repository,
        super(FavorInitial()) {
    on<FetchFavorInfoEvent>((event, emit) async {
      try {
        emit(InProgress());

        final List<YelpRestaurantSummaryInfo> favorInfos =
            await this._repository.fetchFavorInfos(event.isRefreshLocalOnly);

        emit(Success(favorInfos: favorInfos));
      } on Exception catch (_) {
        emit(Failure());
      }
    });
  }
}
