part of 'menu_vision_bloc.dart';

@immutable
sealed class MenuVisionState extends Equatable {
  const MenuVisionState();

  @override
  List<Object?> get props => [];
}

/// 初始狀態（尚未觸發任何分析）
class MenuVisionInitial extends MenuVisionState {
  const MenuVisionInitial();
}

/// 分析進行中（顯示 loading skeleton）
class MenuVisionLoading extends MenuVisionState {
  const MenuVisionLoading();
}

/// 分析成功（持 DishCatalogComponent 供 UI 渲染）
class MenuVisionSuccess extends MenuVisionState {
  final DishCatalogComponent catalog;

  const MenuVisionSuccess({required this.catalog});

  @override
  List<Object?> get props => [catalog];
}

/// 分析失敗（含錯誤訊息，供 UI 顯示重試按鈕）
class MenuVisionFailure extends MenuVisionState {
  final String message;

  const MenuVisionFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// 使用者主動取消拍攝（靜默返回，不顯示錯誤）
class MenuVisionCancelled extends MenuVisionState {
  const MenuVisionCancelled();
}
