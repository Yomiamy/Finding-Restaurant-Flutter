part of 'RestaurantDetailBloc.dart';

@immutable
abstract class RestaurantDetailState extends Equatable  {
  const RestaurantDetailState();

  @override
  List<Object> get props => [];
}

class RestaurantDetailInitial extends RestaurantDetailState {

  const RestaurantDetailInitial();

  @override
  String toString() => "RestaurantDetail page init state.";
}

class InProgress extends RestaurantDetailState {

  const InProgress();

  @override
  String toString() => "Loading detail info";
}

class Success extends RestaurantDetailState {

  final YelpRestaurantDetailInfo detailInfo;
  final YelpReviewInfo reviewInfo;
  final String staticMapUrl;

  const Success({required this.detailInfo, required this.reviewInfo, required this.staticMapUrl});

  @override
  List<Object> get props => [detailInfo.hashCode, reviewInfo.hashCode];

  @override
  String toString() => "Success get detail info ${this.detailInfo}";
}

class Failure extends RestaurantDetailState {

  const Failure();

  @override
  String toString() => "Fail get detail info";
}

class ToggleFavorSuccess extends RestaurantDetailState {
  const ToggleFavorSuccess();

  @override
  String toString() => "Toggle favor success.";
}
