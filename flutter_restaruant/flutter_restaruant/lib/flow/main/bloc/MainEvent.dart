part of 'MainBloc.dart';

@immutable
abstract class MainEvent extends Equatable {

  const MainEvent();

  @override
  List<Object> get props => [];
}

class FetchSearchInfo extends MainEvent {

  final int price;
  final int openAt;
  final String sortBy;

  const FetchSearchInfo({required this.price, required this.openAt, required this.sortBy});

  @override
  String toString() => "Fetch search info event.";
}
