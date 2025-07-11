part of 'FavorBloc.dart';

@immutable
abstract class FavorEvent extends Equatable {
  const FavorEvent();

  @override
  List<Object> get props => [];
}

class FetchFavorInfoEvent extends FavorEvent {
  final bool isRefreshLocalOnly;

  const FetchFavorInfoEvent(this.isRefreshLocalOnly);

  @override
  List<Object> get props => [];
}

class UpdateFavorInfoEvent extends FavorEvent {
  final YelpRestaurantSummaryInfo summaryInfo;

  const UpdateFavorInfoEvent({required this.summaryInfo});

  @override
  List<Object> get props => [this.summaryInfo.hashCode];
}
