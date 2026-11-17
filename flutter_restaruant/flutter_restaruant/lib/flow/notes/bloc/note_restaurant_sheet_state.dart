import 'package:equatable/equatable.dart';

import '../../../domain/entities/restaurant_detail_entity.dart';

/// 筆記餐廳摘要彈窗 BLoC 的狀態。
sealed class NoteRestaurantSheetState extends Equatable {
  const NoteRestaurantSheetState();

  @override
  List<Object?> get props => [];
}

/// 尚未開始載入摘要的初始狀態。
final class NoteRestaurantSheetInitial extends NoteRestaurantSheetState {
  const NoteRestaurantSheetInitial();
}

/// 筆記未綁定 `restaurantId`，降級顯示純文字摘要與地圖搜尋。
final class NoteRestaurantSheetUnlinked extends NoteRestaurantSheetState {
  const NoteRestaurantSheetUnlinked();
}

/// 正在向資料層查詢餐廳詳情與收藏狀態。
final class NoteRestaurantSheetLoading extends NoteRestaurantSheetState {
  const NoteRestaurantSheetLoading();
}

/// 餐廳詳情載入完成（收藏查詢逾時或失敗時 `isFavor` 會安全降級為 `false`）。
final class NoteRestaurantSheetLoaded extends NoteRestaurantSheetState {
  final RestaurantDetailEntity detail;
  final bool isFavor;

  const NoteRestaurantSheetLoaded({required this.detail, this.isFavor = false});

  @override
  List<Object?> get props => [detail, isFavor];
}

/// ID 格式不合法、資料層不可用或 API 回應異常失敗。
final class NoteRestaurantSheetFailure extends NoteRestaurantSheetState {
  final String message;

  const NoteRestaurantSheetFailure(this.message);

  @override
  List<Object?> get props => [message];
}
