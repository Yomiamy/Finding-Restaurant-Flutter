import 'package:equatable/equatable.dart';

/// 筆記餐廳摘要彈窗 BLoC 的輸入事件。
sealed class NoteRestaurantSheetEvent extends Equatable {
  const NoteRestaurantSheetEvent();

  @override
  List<Object?> get props => [];
}

/// 依筆記綁定的餐廳 ID 載入（或重試）餐廳詳情與收藏狀態。
final class FetchNoteRestaurantSummary extends NoteRestaurantSheetEvent {
  final String restaurantId;

  const FetchNoteRestaurantSummary({required this.restaurantId});

  @override
  List<Object?> get props => [restaurantId];
}
