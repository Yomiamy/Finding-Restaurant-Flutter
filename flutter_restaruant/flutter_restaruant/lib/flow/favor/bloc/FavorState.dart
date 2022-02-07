part of 'FavorBloc.dart';

@immutable
abstract class FavorState extends Equatable {
  const FavorState();

  @override
  List<Object> get props => [];
}

class FavorInitial extends FavorState {}

class InProgress extends FavorState {

  const InProgress();

  @override
  String toString() => "Loading detail info";
}

class Success extends FavorState {

  final List<YelpRestaurantSummaryInfo> favorInfos;

  const Success({required this.favorInfos});

  @override
  List<Object> get props => this.favorInfos;

  @override
  String toString() =>  "Get favor store info successfully";
}

class Failure extends FavorState {
  const Failure();

  @override
  String toString() =>  "Fail get favor store info";
}
