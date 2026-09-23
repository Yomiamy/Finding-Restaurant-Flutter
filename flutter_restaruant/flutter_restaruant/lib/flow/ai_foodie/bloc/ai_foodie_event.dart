import 'package:equatable/equatable.dart';
import '../model/ai_foodie_model.dart';

/// AI 覓食助理 BLoC 事件基類
sealed class AiFoodieEvent extends Equatable {
  const AiFoodieEvent();

  @override
  List<Object?> get props => [];
}

/// 載入初始歡迎訊息與建議情境標籤
final class LoadInitialSuggestions extends AiFoodieEvent {
  const LoadInitialSuggestions();
}

/// 發送使用者文字需求
final class SendUserPrompt extends AiFoodieEvent {
  const SendUserPrompt(this.prompt);

  final String prompt;

  @override
  List<Object?> get props => [prompt];
}

/// 點擊 GenUI 行動標籤
final class TriggerActionChip extends AiFoodieEvent {
  const TriggerActionChip(this.chip);

  final ActionChipModel chip;

  @override
  List<Object?> get props => [chip];
}

/// 開啟命運轉盤彈窗
final class OpenRoulette extends AiFoodieEvent {
  const OpenRoulette({required this.title, required this.options});

  final String title;
  final List<String> options;

  @override
  List<Object?> get props => [title, options];
}

/// 轉盤抽籤完成並選出結果
final class SpinRouletteWinnerSelected extends AiFoodieEvent {
  const SpinRouletteWinnerSelected(this.winner);

  final String winner;

  @override
  List<Object?> get props => [winner];
}

/// 關閉命運轉盤彈窗
final class CloseRoulette extends AiFoodieEvent {
  const CloseRoulette();
}

/// 重置對話助理
final class ResetAiFoodie extends AiFoodieEvent {
  const ResetAiFoodie();
}
