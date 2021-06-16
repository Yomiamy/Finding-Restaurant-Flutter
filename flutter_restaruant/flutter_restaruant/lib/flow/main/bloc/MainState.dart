part of 'MainBloc.dart';

@immutable
abstract class MainState extends Equatable {

  const MainState();

  @override
  List<Object> get props => [];
}

class MainInitial extends MainState {

  const MainInitial();

  @override
  String toString() => "Main page init state.";
}

class InProgress extends MainState {

  const InProgress();

  @override
  String toString() => "Loading search info";
}

class Success extends MainState {

  final YelpSearchInfo searchInfo;

  const Success({required this.searchInfo});

  @override
  List<Object> get props => [searchInfo.hashCode];

  @override
  String toString() => "Success get search info ${this.searchInfo}";
}

class Failure extends MainState {

  const Failure();

  @override
  String toString() => "Fail get search info";
}
