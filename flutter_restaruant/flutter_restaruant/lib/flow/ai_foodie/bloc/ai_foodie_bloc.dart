import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../domain/repositories/ai_foodie_repository.dart';
import '../../../generated/l10n.dart';
import 'ai_foodie_event.dart';
import 'ai_foodie_state.dart';

/// AI 覓食助理狀態管理 BLoC
class AiFoodieBloc extends Bloc<AiFoodieEvent, AiFoodieState> {
  AiFoodieBloc({
    required AiFoodieRepository repository,
    List<RestaurantEntity>? candidateRestaurants,
  })  : _repository = repository,
        _candidateRestaurants = candidateRestaurants,
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
  final List<RestaurantEntity>? _candidateRestaurants;
  int _requestToken = 0;

  Future<void> _onLoadInitialSuggestions(
    LoadInitialSuggestions event,
    Emitter<AiFoodieState> emit,
  ) async {
    if (state.messages.isNotEmpty) return;

    final token = ++_requestToken;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final initialMessages = await _repository.getInitialSuggestions();
      if (token != _requestToken) return;
      emit(state.copyWith(
        messages: initialMessages,
        isLoading: false,
      ));
    } catch (e) {
      if (token != _requestToken) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: S.current.ai_foodie_error_load_suggestions(e.toString()),
      ));
    }
  }

  Future<void> _onSendUserPrompt(
    SendUserPrompt event,
    Emitter<AiFoodieState> emit,
  ) async {
    final trimmed = event.prompt.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final token = ++_requestToken;
    final priorHistory = state.messages;
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
        history: priorHistory,
        candidateRestaurants: _candidateRestaurants,
      );

      if (token != _requestToken) return;

      emit(state.copyWith(
        messages: [...updatedMessages, assistantResponse],
        isLoading: false,
      ));
    } catch (e) {
      if (token != _requestToken) return;

      emit(state.copyWith(
        isLoading: false,
        errorMessage: S.current.ai_foodie_error_connect_assistant(e.toString()),
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
      final title = payload['title'] is String
          ? payload['title'] as String
          : _rouletteDefaultTitle();
      final rawOptions = payload['options'];
      if (rawOptions is! List) return;
      final options = rawOptions
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toList(growable: false);

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
          text: _rouletteResultMessage(event.winner),
        ),
      ],
    ));
  }

  String _rouletteDefaultTitle() {
    try {
      return S.current.ai_foodie_roulette_default_title;
    } catch (_) {
      return '今晚吃什麼？命運大轉盤';
    }
  }

  String _rouletteResultMessage(String winner) {
    try {
      return S.current.ai_foodie_roulette_result_msg(winner);
    } catch (_) {
      return '🎲 命運轉盤為您抽出了最棒的選擇：\n👉 **$winner** 👈\n祝您今晚用餐愉快，吃得開心滿足！';
    }
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
    _requestToken++;
    emit(AiFoodieState.initial());
    add(const LoadInitialSuggestions());
  }
}
