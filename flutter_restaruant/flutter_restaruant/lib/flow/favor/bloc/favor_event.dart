part of 'favor_bloc.dart';

@immutable
abstract class FavorEvent extends Equatable {
  const FavorEvent();

  @override
  List<Object> get props => [];
}

class FetchFavorInfoEvent extends FavorEvent {
  const FetchFavorInfoEvent();

  @override
  List<Object> get props => [];
}

class UpdateFavorInfoEvent extends FavorEvent {
  final RestaurantEntity summaryInfo;

  const UpdateFavorInfoEvent({required this.summaryInfo});

  @override
  List<Object> get props => [summaryInfo.hashCode];
}
