import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../domain/repositories/ai_foodie_repository.dart';
import 'ai_foodie_event.dart';
import 'ai_foodie_state.dart';

/// AI 覓食助理狀態管理 BLoC
class AiFoodieBloc extends Bloc<AiFoodieEvent, AiFoodieState> {
  AiFoodieBloc({required AiFoodieRepository repository})
      : _repository = repository,
        super(AiFoodieState.initial()) {
    on<LoadInitialSuggestions>(_onLoadInitialSuggestions);
    on<SendUserPrompt>(_onSendUserPrompt);
    on<TriggerActionChip>(_onTriggerActionChip);
    on<OpenRoulette>(_onOpenRoulette);
    on<SpinRouletteWinnerSelected>(_onSpinRouletteWinnerSelected);
    on<CloseRoulette>(_onCloseRoulette);
    on<ResetAiFoodie>(_onResetAiFoodie);
  }

  final AiFoodieRepository _repository;

  Future<void> _onLoadInitialSuggestions(
    LoadInitialSuggestions event,
    Emitter<AiFoodieState> emit,
  ) async {
    if (state.messages.isNotEmpty) return;

    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final initialMessages = await _repository.getInitialSuggestions();
      emit(state.copyWith(
        messages: initialMessages,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '載入建議時發生錯誤：$e',
      ));
    }
  }

  Future<void> _onSendUserPrompt(
    SendUserPrompt event,
    Emitter<AiFoodieState> emit,
  ) async {
    final trimmed = event.prompt.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final userMessage = AiFoodieMessage.user(trimmed);
    final updatedMessages = [...state.messages, userMessage];

    emit(state.copyWith(
      messages: updatedMessages,
      isLoading: true,
      clearError: true,
    ));

    try {
      final assistantResponse = await _repository.askAssistant(
        trimmed,
        history: updatedMessages,
      );

      emit(state.copyWith(
        messages: [...updatedMessages, assistantResponse],
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '連線助理時發生錯誤：$e',
      ));
    }
  }

  void _onTriggerActionChip(
    TriggerActionChip event,
    Emitter<AiFoodieState> emit,
  ) {
    final action = event.chip.action;
    final payload = event.chip.payload;

    if (action == 'query') {
      final prompt = payload['prompt'] as String?;
      if (prompt != null && prompt.isNotEmpty) {
        add(SendUserPrompt(prompt));
      }
      return;
    }

    if (action == 'open_roulette') {
      final title = payload['title'] as String? ?? '今晚吃什麼？命運大轉盤';
      final rawOptions = payload['options'] as List<Object?>? ?? const [];
      final options = rawOptions.whereType<String>().toList();

      if (options.isNotEmpty) {
        add(OpenRoulette(title: title, options: options));
      }
    }
  }

  void _onOpenRoulette(
    OpenRoulette event,
    Emitter<AiFoodieState> emit,
  ) {
    emit(state.copyWith(
      isRouletteVisible: true,
      rouletteTitle: event.title,
      rouletteOptions: event.options,
      clearWinner: true,
    ));
  }

  void _onSpinRouletteWinnerSelected(
    SpinRouletteWinnerSelected event,
    Emitter<AiFoodieState> emit,
  ) {
    emit(state.copyWith(
      selectedRouletteWinner: event.winner,
      isRouletteVisible: false,
      messages: [
        ...state.messages,
        AiFoodieMessage.assistant(
          text: '🎲 命運轉盤為您抽出了最棒的選擇：\n👉 **${event.winner}** 👈\n祝您今晚用餐愉快，吃得開心滿足！',
        ),
      ],
    ));
  }

  void _onCloseRoulette(
    CloseRoulette event,
    Emitter<AiFoodieState> emit,
  ) {
    emit(state.copyWith(isRouletteVisible: false));
  }

  void _onResetAiFoodie(
    ResetAiFoodie event,
    Emitter<AiFoodieState> emit,
  ) {
    emit(AiFoodieState.initial());
  }
}
