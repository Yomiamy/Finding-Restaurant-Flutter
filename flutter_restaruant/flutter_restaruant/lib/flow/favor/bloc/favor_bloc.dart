import 'package:bloc/bloc.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../../../domain/repositories/repositories_barrel.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
part 'favor_event.dart';
part 'favor_state.dart';

class FavorBloc extends Bloc<FavorEvent, FavorState> {
  final FavorRepository _repository;

  FavorBloc({required FavorRepository repository})
    : _repository = repository,
      super(FavorInitial()) {
    on<FetchFavorInfoEvent>((event, emit) async {
      try {
        emit(const InProgress());

        final List<RestaurantEntity> favorInfos = await _repository
            .fetchFavorInfos();

        emit(Success(favorInfos: favorInfos));
      } on Exception catch (_) {
        emit(const Failure());
      }
    });
  }
}
