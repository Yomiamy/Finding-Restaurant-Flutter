part of 'restaurant_detail_bloc.dart';

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
  String toString() => 'Fetch detail info event.';

  @override
  List<Object> get props => [id];
}

class ToggleFavor extends RestaurantDetailEvent {
  final RestaurantEntity summaryInfo;

  const ToggleFavor({required this.summaryInfo});

  @override
  String toString() => 'ToggleFavor event.';

  @override
  List<Object> get props => [summaryInfo.id ?? '', summaryInfo.favor];
}
