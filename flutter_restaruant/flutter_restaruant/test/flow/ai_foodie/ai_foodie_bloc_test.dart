import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/ai_foodie_repository.dart';
import 'package:flutter_restaruant/flow/ai_foodie/bloc/bloc_barrel.dart';
import 'package:flutter_restaruant/flow/ai_foodie/model/ai_foodie_model.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAiFoodieRepository implements AiFoodieRepository {
  List<AiFoodieMessage>? initialSuggestionsResult;
  AiFoodieMessage? askAssistantResult;
  bool shouldThrow = false;
  List<AiFoodieMessage>? lastHistory;

  @override
  Future<List<AiFoodieMessage>> getInitialSuggestions() {
    if (shouldThrow) return Future.error(Exception('模擬建議取得失敗'));
    return Future.value(
      initialSuggestionsResult ??
          [
            AiFoodieMessage.assistant(
              text: '歡迎使用 AI 覓食助理',
              components: const [
                ActionChipGroupComponent(
                  chips: [
                    ActionChipItem(
                      label: '居酒屋',
                      action: 'query',
                      payload: {'prompt': '我想吃居酒屋'},
                    ),
                  ],
                ),
              ],
            ),
          ],
    );
  }

  @override
  Future<AiFoodieMessage> askAssistant(
    String prompt, {
    List<AiFoodieMessage>? history,
    List<RestaurantEntity>? candidateRestaurants,
  }) {
    lastHistory = history;
    if (shouldThrow) return Future.error(Exception('模擬對話連線失敗'));
    return Future.value(
      askAssistantResult ??
          AiFoodieMessage.assistant(
            text: '為您找到好吃的餐廳：$prompt',
            components: const [
              ComparisonMatrixComponent(
                title: '對比清單',
                items: [
                  RestaurantComparisonItem(
                    id: 'r1',
                    name: '測試餐廳 1',
                    rating: 4.8,
                    highlights: ['好吃'],
                  ),
                  RestaurantComparisonItem(
                    id: 'r2',
                    name: '測試餐廳 2',
                    rating: 4.6,
                    highlights: ['便宜'],
                  ),
                ],
              ),
            ],
          ),
    );
  }
}

void main() {
  group('AiFoodieBloc Tests', () {
    late MockAiFoodieRepository repository;
    late AiFoodieBloc bloc;

    setUp(() async {
      await S.load(const Locale('zh', 'TW'));
      repository = MockAiFoodieRepository();
      bloc = AiFoodieBloc(repository: repository);
    });

    tearDown(() {
      bloc.close();
    });

    test('初始狀態為空 messages 且 isLoading 為 false', () {
      expect(bloc.state.messages, isEmpty);
      expect(bloc.state.isLoading, isFalse);
    });

    test('LoadInitialSuggestions 成功載入歡迎訊息', () async {
      bloc.add(const LoadInitialSuggestions());
      await pumpEventQueue();

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.messages.length, 1);
      expect(bloc.state.messages.first.text, contains('歡迎使用'));
    });

    test('SendUserPrompt 依序追加使用者訊息與助理回應', () async {
      bloc.add(const SendUserPrompt('4人吃居酒屋'));
      await pumpEventQueue();

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.messages.length, 2);
      expect(bloc.state.messages[0].isUser, isTrue);
      expect(bloc.state.messages[0].text, '4人吃居酒屋');
      expect(bloc.state.messages[1].isUser, isFalse);
      expect(bloc.state.messages[1].text, contains('為您找到好吃的餐廳'));
    });

    test('SendUserPrompt 空字串直接被忽略', () async {
      bloc.add(const SendUserPrompt('   '));
      await pumpEventQueue();

      expect(bloc.state.messages, isEmpty);
      expect(bloc.state.isLoading, isFalse);
    });

    test('SendUserPrompt 錯誤時更新 errorMessage', () async {
      repository.shouldThrow = true;
      bloc.add(const SendUserPrompt('4人聚餐'));
      await pumpEventQueue();

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.errorMessage, contains('連線助理時發生錯誤'));
    });

    test('TriggerActionChip query 動作正確觸發送出 Prompt', () async {
      const chip = ActionChipModel(
        label: '約會餐廳',
        action: 'query',
        payload: {'prompt': '推薦浪漫約會小館'},
      );

      bloc.add(const TriggerActionChip(chip));
      await pumpEventQueue();

      expect(bloc.state.messages.length, 2);
      expect(bloc.state.messages[0].text, '推薦浪漫約會小館');
    });

    test('OpenRoulette 與 SpinRouletteWinnerSelected 狀態流轉正確', () async {
      bloc.add(const OpenRoulette(title: '轉盤抽籤', options: ['餐廳 A', '餐廳 B']));
      await pumpEventQueue();

      expect(bloc.state.isRouletteVisible, isTrue);
      expect(bloc.state.rouletteTitle, '轉盤抽籤');
      expect(bloc.state.rouletteOptions, ['餐廳 A', '餐廳 B']);

      bloc.add(const SpinRouletteWinnerSelected('餐廳 A'));
      await pumpEventQueue();

      expect(bloc.state.isRouletteVisible, isFalse);
      expect(bloc.state.selectedRouletteWinner, '餐廳 A');
      expect(bloc.state.messages.last.text, contains('餐廳 A'));
    });

    test('ResetAiFoodie 正確重置狀態並重新載入初始建議', () async {
      bloc.add(const SendUserPrompt('測試'));
      await pumpEventQueue();
      expect(bloc.state.messages.isNotEmpty, isTrue);

      bloc.add(const ResetAiFoodie());
      await pumpEventQueue();

      expect(bloc.state.messages.length, 1);
      expect(bloc.state.messages.first.text, contains('歡迎使用'));
      expect(bloc.state.isLoading, isFalse);
    });

    test('ResetAiFoodie 會作廢先前的非同步請求避免覆蓋重設狀態', () async {
      bloc.add(const SendUserPrompt('延遲提問'));
      bloc.add(const ResetAiFoodie());
      await pumpEventQueue();

      expect(bloc.state.messages.length, 1);
      expect(bloc.state.messages.first.text, contains('歡迎使用'));
      expect(bloc.state.isLoading, isFalse);
    });

    test('messageModels 與 messages 同步', () async {
      bloc.add(const LoadInitialSuggestions());
      await pumpEventQueue();

      expect(
        bloc.state.messageModels.single.text,
        bloc.state.messages.single.text,
      );
    });

    test('history 是送出前的 state.messages（entity）', () async {
      bloc.add(const SendUserPrompt('第一句'));
      await pumpEventQueue();
      final priorMessages = bloc.state.messages;

      bloc.add(const SendUserPrompt('第二句'));
      await pumpEventQueue();

      expect(repository.lastHistory, priorMessages);
    });
  });
}
