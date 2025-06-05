part of 'RestaurantDetailBloc.dart';

@immutable
abstract class RestaurantDetailEvent extends Equatable {
  const RestaurantDetailEvent();

  @override
  List<Object> get props => [];
}

class FetchDetailInfo extends RestaurantDetailEvent {
  final String id;

  const FetchDetailInfo({required this.id});

  @override
  String toString() => "Fetch detail info event.";

  @override
  List<Object> get props => [this.id];
}

class ToggleFavor extends RestaurantDetailEvent {
  // 透過uid取得喜好列表
  final YelpRestaurantSummaryInfo summaryInfo;

  const ToggleFavor({required this.summaryInfo});

  @override
  String toString() => "ToggleFavor event.";
}
