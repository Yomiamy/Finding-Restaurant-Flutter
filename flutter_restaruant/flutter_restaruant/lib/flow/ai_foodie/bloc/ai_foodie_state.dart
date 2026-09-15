import 'package:equatable/equatable.dart';
import '../../../domain/entities/entities_barrel.dart';

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

  final List<AiFoodieMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final bool isRouletteVisible;
  final String? rouletteTitle;
  final List<String> rouletteOptions;
  final String? selectedRouletteWinner;

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
