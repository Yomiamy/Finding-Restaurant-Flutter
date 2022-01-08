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
}