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

  final List<YelpRestaurantSummaryInfo> summaryInfos;

  const Success({required this.summaryInfos});

  @override
  List<Object> get props => this.summaryInfos;

  @override
  String toString() => "Success get summary infos ${this.summaryInfos}";
}

class Failure extends MainState {

  const Failure();

  @override
  String toString() => "Fail get search info";
}

class ResetSuccess extends MainState {
  const ResetSuccess();

  @override
  String toString() => "Sucess reset offset";
}


class LoadMoreSuccess extends MainState {

  final List<YelpRestaurantSummaryInfo> summaryInfos = [];

  LoadMoreSuccess({required List<YelpRestaurantSummaryInfo> summaryInfos}) {
    this.summaryInfos.addAll(summaryInfos);
  }

  @override
  List<Object> get props => this.summaryInfos;

  @override
  String toString() => "Load more success.";
}
