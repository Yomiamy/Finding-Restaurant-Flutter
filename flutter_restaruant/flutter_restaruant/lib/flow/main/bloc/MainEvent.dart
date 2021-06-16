part of 'MainBloc.dart';

@immutable
abstract class MainEvent extends Equatable {

  const MainEvent();

  @override
  List<Object> get props => [];
}

class FetchSearchInfo extends MainEvent {

  const FetchSearchInfo();

  @override
  String toString() => "Fetch search info event.";
}
