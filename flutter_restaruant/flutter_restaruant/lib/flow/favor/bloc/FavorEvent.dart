part of 'FavorBloc.dart';

@immutable
abstract class FavorEvent extends Equatable {
  const FavorEvent();

  @override
  List<Object> get props => [];
}

class FetchFavorInfoEvent extends FavorEvent {
  // 透過uid取得喜好列表
  final String uid;

  const FetchFavorInfoEvent({required this.uid});

  @override
  List<Object> get props => [this.uid];
}


class UpdateFavorInfoEvent extends FavorEvent {
  // 透過uid取得喜好列表
  final String uid;
  final YelpRestaurantSummaryInfo summaryInfo;

  const UpdateFavorInfoEvent({required this.uid, required this.summaryInfo});

  @override
  List<Object> get props => [this.uid, this.summaryInfo.hashCode];
}