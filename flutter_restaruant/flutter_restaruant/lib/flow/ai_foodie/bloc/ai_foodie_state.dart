import 'package:equatable/equatable.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../model/ai_foodie_model.dart';

/// AI 覓食助理狀態類別
final class AiFoodieState extends Equatable {
  const AiFoodieState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isRouletteVisible = false,
    this.rouletteTitle,
    this.rouletteOptions = const [],
    this.selectedRouletteWinner,
  });

  factory AiFoodieState.initial() => const AiFoodieState();

  /// LLM 對話歷史的唯一來源（`repo.askAssistant(history:)` 需要 entity 才能 `toJson`）
  final List<AiFoodieMessage> messages;

  final bool isLoading;
  final String? errorMessage;
  final bool isRouletteVisible;
  final String? rouletteTitle;
  final List<String> rouletteOptions;
  final String? selectedRouletteWinner;

  /// View 顯示用的 UI model，每次由 [messages] 衍生，不存第二份所以不可能不同步。
  // ponytail: 每次存取都重新轉換，對話量大到有感時再改為 BLoC 端快取
  List<AiFoodieMessageModel> get messageModels =>
      messages.map(AiFoodieMessageModel.fromEntity).toList(growable: false);

  AiFoodieState copyWith({
    List<AiFoodieMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    bool? isRouletteVisible,
    String? rouletteTitle,
    List<String>? rouletteOptions,
    String? selectedRouletteWinner,
    bool clearError = false,
    bool clearWinner = false,
  }) {
    return AiFoodieState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isRouletteVisible: isRouletteVisible ?? this.isRouletteVisible,
      rouletteTitle: rouletteTitle ?? this.rouletteTitle,
      rouletteOptions: rouletteOptions ?? this.rouletteOptions,
      selectedRouletteWinner: clearWinner
          ? null
          : (selectedRouletteWinner ?? this.selectedRouletteWinner),
    );
  }

  @override
  List<Object?> get props => [
    messages,
    isLoading,
    errorMessage,
    isRouletteVisible,
    rouletteTitle,
    rouletteOptions,
    selectedRouletteWinner,
  ];
}
