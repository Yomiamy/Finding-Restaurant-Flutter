part of 'MainBloc.dart';

@immutable
abstract class MainEvent extends Equatable {
  const MainEvent();

  @override
  List<Object> get props => [];
}

class FetchSearchInfo extends MainEvent {
  final int? price;
  final int? openAt;
  final String? sortBy;

  const FetchSearchInfo({this.price, this.openAt, this.sortBy});

  @override
  String toString() => "Fetch search info event.";
}

class Reset extends MainEvent {
  const Reset();

  @override
  String toString() => "Reset offset event.";
}

class LoadMore extends MainEvent {
  const LoadMore();

  @override
  String toString() => "Load more event.";
}

class FilterListByKeyword extends MainEvent {
  final String keyword;
  final String? sortByStr;

  const FilterListByKeyword({this.keyword = "", this.sortByStr});

  @override
  String toString() => "FilterListByKeyword event.";
}

class ToggleFavor extends MainEvent {
  // 透過uid取得喜好列表
  final YelpRestaurantSummaryInfo summaryInfo;

  const ToggleFavor({required this.summaryInfo});

  @override
  String toString() => "ToggleFavor event.";
}

// 請求FCM
class NotificationSetup extends MainEvent {
  const NotificationSetup();

  @override
  String toString() => "NotificationSetup event.";
}
