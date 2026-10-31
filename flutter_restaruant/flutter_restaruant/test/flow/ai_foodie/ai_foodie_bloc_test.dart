import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/ai_foodie_repository.dart';
import 'package:flutter_restaruant/flow/ai_foodie/bloc/bloc_barrel.dart';
import 'package:flutter_restaruant/flow/ai_foodie/models/ai_foodie_model.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAiFoodieRepository extends Mock implements AiFoodieRepository {}

class _Data {
  static final List<AiFoodieMessage> welcome = [
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
  ];

  static AiFoodieMessage reply(String prompt) => AiFoodieMessage.assistant(
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
  );
}

void main() {
  group('AiFoodieBloc Tests', () {
    late _MockAiFoodieRepository repository;

    setUp(() async {
      await S.load(const Locale('zh', 'TW'));
      repository = _MockAiFoodieRepository();
      when(
        () => repository.getInitialSuggestions(),
      ).thenAnswer((_) async => _Data.welcome);
      when(
        () => repository.askAssistant(
          any(),
          history: any(named: 'history'),
          candidateRestaurants: any(named: 'candidateRestaurants'),
        ),
      ).thenAnswer(
        (inv) async => _Data.reply(inv.positionalArguments.first as String),
      );
    });

    test('初始狀態為空 messages 且 isLoading 為 false', () {
      final bloc = AiFoodieBloc(repository: repository);
      expect(bloc.state.messages, isEmpty);
      expect(bloc.state.isLoading, isFalse);
      bloc.close();
    });

    blocTest<AiFoodieBloc, AiFoodieState>(
      'LoadInitialSuggestions 成功載入歡迎訊息',
      build: () => AiFoodieBloc(repository: repository),
      act: (bloc) => bloc.add(const LoadInitialSuggestions()),
      expect: () => [
        isA<AiFoodieState>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<AiFoodieState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.messages.length, 'messages.length', 1)
            .having(
              (s) => s.messages.first.text,
              'messages.first.text',
              contains('歡迎使用'),
            ),
      ],
      verify: (_) => verify(() => repository.getInitialSuggestions()).called(1),
    );

    blocTest<AiFoodieBloc, AiFoodieState>(
      'SendUserPrompt 依序追加使用者訊息與助理回應',
      build: () => AiFoodieBloc(repository: repository),
      act: (bloc) => bloc.add(const SendUserPrompt('4人吃居酒屋')),
      expect: () => [
        isA<AiFoodieState>()
            .having((s) => s.isLoading, 'isLoading', isTrue)
            .having((s) => s.messages.length, 'messages.length', 1)
            .having((s) => s.messages[0].isUser, 'isUser', isTrue)
            .having((s) => s.messages[0].text, 'text', '4人吃居酒屋'),
        isA<AiFoodieState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.messages.length, 'messages.length', 2)
            .having((s) => s.messages[0].isUser, 'isUser', isTrue)
            .having((s) => s.messages[0].text, 'text', '4人吃居酒屋')
            .having((s) => s.messages[1].isUser, 'isUser', isFalse)
            .having((s) => s.messages[1].text, 'text', contains('為您找到好吃的餐廳')),
      ],
    );

    blocTest<AiFoodieBloc, AiFoodieState>(
      'SendUserPrompt 空字串直接被忽略',
      build: () => AiFoodieBloc(repository: repository),
      act: (bloc) => bloc.add(const SendUserPrompt('   ')),
      expect: () => <AiFoodieState>[],
      verify: (bloc) {
        expect(bloc.state.messages, isEmpty);
        expect(bloc.state.isLoading, isFalse);
      },
    );

    blocTest<AiFoodieBloc, AiFoodieState>(
      'LoadInitialSuggestions 錯誤時更新 errorMessage',
      build: () {
        when(
          () => repository.getInitialSuggestions(),
        ).thenAnswer((_) async => throw Exception('模擬建議取得失敗'));
        return AiFoodieBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const LoadInitialSuggestions()),
      expect: () => [
        isA<AiFoodieState>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<AiFoodieState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('模擬建議取得失敗'),
            ),
      ],
    );

    blocTest<AiFoodieBloc, AiFoodieState>(
      'SendUserPrompt 錯誤時更新 errorMessage',
      build: () {
        when(
          () => repository.askAssistant(
            any(),
            history: any(named: 'history'),
            candidateRestaurants: any(named: 'candidateRestaurants'),
          ),
        ).thenAnswer((_) async => throw Exception('模擬對話連線失敗'));
        return AiFoodieBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const SendUserPrompt('4人聚餐')),
      expect: () => [
        isA<AiFoodieState>()
            .having((s) => s.isLoading, 'isLoading', isTrue)
            .having((s) => s.messages.length, 'messages.length', 1),
        isA<AiFoodieState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('連線助理時發生錯誤'),
            ),
      ],
    );

    blocTest<AiFoodieBloc, AiFoodieState>(
      'TriggerActionChip query 動作正確觸發送出 Prompt',
      build: () => AiFoodieBloc(repository: repository),
      act: (bloc) => bloc.add(
        const TriggerActionChip(
          ActionChipModel(
            label: '約會餐廳',
            action: 'query',
            payload: {'prompt': '推薦浪漫約會小館'},
          ),
        ),
      ),
      expect: () => [
        isA<AiFoodieState>()
            .having((s) => s.isLoading, 'isLoading', isTrue)
            .having((s) => s.messages.length, 'messages.length', 1)
            .having((s) => s.messages[0].text, 'text', '推薦浪漫約會小館'),
        isA<AiFoodieState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.messages.length, 'messages.length', 2)
            .having((s) => s.messages[0].text, 'text', '推薦浪漫約會小館'),
      ],
    );

    blocTest<AiFoodieBloc, AiFoodieState>(
      'OpenRoulette 與 SpinRouletteWinnerSelected 狀態流轉正確',
      build: () => AiFoodieBloc(repository: repository),
      act: (bloc) {
        bloc.add(const OpenRoulette(title: '轉盤抽籤', options: ['餐廳 A', '餐廳 B']));
        bloc.add(const SpinRouletteWinnerSelected('餐廳 A'));
      },
      expect: () => [
        isA<AiFoodieState>()
            .having((s) => s.isRouletteVisible, 'isRouletteVisible', isTrue)
            .having((s) => s.rouletteTitle, 'rouletteTitle', '轉盤抽籤')
            .having((s) => s.rouletteOptions, 'rouletteOptions', [
              '餐廳 A',
              '餐廳 B',
            ]),
        isA<AiFoodieState>()
            .having((s) => s.isRouletteVisible, 'isRouletteVisible', isFalse)
            .having(
              (s) => s.selectedRouletteWinner,
              'selectedRouletteWinner',
              '餐廳 A',
            )
            .having((s) => s.messages.last.text, 'last.text', contains('餐廳 A')),
      ],
    );

    blocTest<AiFoodieBloc, AiFoodieState>(
      'ResetAiFoodie 正確重置狀態並重新載入初始建議',
      build: () => AiFoodieBloc(repository: repository),
      seed: () => AiFoodieState(messages: [AiFoodieMessage.user('測試')]),
      act: (bloc) => bloc.add(const ResetAiFoodie()),
      expect: () => [
        AiFoodieState.initial(),
        isA<AiFoodieState>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<AiFoodieState>()
            .having((s) => s.messages.length, 'messages.length', 1)
            .having(
              (s) => s.messages.first.text,
              'messages.first.text',
              contains('歡迎使用'),
            )
            .having((s) => s.isLoading, 'isLoading', isFalse),
      ],
    );

    blocTest<AiFoodieBloc, AiFoodieState>(
      'ResetAiFoodie 會作廢先前的非同步請求避免覆蓋重設狀態',
      build: () {
        when(
          () => repository.askAssistant(
            any(),
            history: any(named: 'history'),
            candidateRestaurants: any(named: 'candidateRestaurants'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return _Data.reply('延遲提問');
        });
        return AiFoodieBloc(repository: repository);
      },
      act: (bloc) {
        bloc.add(const SendUserPrompt('延遲提問'));
        bloc.add(const ResetAiFoodie());
      },
      expect: () => [
        isA<AiFoodieState>()
            .having((s) => s.isLoading, 'isLoading', isTrue)
            .having((s) => s.messages.length, 'messages.length', 1),
        AiFoodieState.initial(),
        isA<AiFoodieState>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<AiFoodieState>()
            .having((s) => s.messages.length, 'messages.length', 1)
            .having(
              (s) => s.messages.first.text,
              'messages.first.text',
              contains('歡迎使用'),
            )
            .having((s) => s.isLoading, 'isLoading', isFalse),
      ],
    );

    blocTest<AiFoodieBloc, AiFoodieState>(
      'messageModels 與 messages 同步',
      build: () => AiFoodieBloc(repository: repository),
      act: (bloc) => bloc.add(const LoadInitialSuggestions()),
      verify: (bloc) {
        expect(
          bloc.state.messageModels.single.text,
          bloc.state.messages.single.text,
        );
      },
    );

    test('messageModels 由建構式傳入的 messages 衍生', () {
      final state = AiFoodieState(messages: [AiFoodieMessage.user('hi')]);
      expect(state.messageModels.single.text, 'hi');
    });

    blocTest<AiFoodieBloc, AiFoodieState>(
      'SendUserPrompt 遇到 Error 往外拋出，不 emit errorMessage',
      build: () {
        when(
          () => repository.askAssistant(
            any(),
            history: any(named: 'history'),
            candidateRestaurants: any(named: 'candidateRestaurants'),
          ),
        ).thenAnswer((_) async => throw StateError('bug'));
        return AiFoodieBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const SendUserPrompt('4人聚餐')),
      expect: () => [
        isA<AiFoodieState>().having((s) => s.isLoading, 'isLoading', isTrue),
      ],
      errors: () => [isA<StateError>()],
    );

    const fixedPriorMessages = [
      AiFoodieMessage(id: 'msg_fixed_1', isUser: true, text: '第一句'),
      AiFoodieMessage(id: 'msg_fixed_2', isUser: false, text: '為您找到好吃的餐廳：第一句'),
    ];

    blocTest<AiFoodieBloc, AiFoodieState>(
      'history 是送出前的 state.messages（entity）',
      build: () => AiFoodieBloc(repository: repository),
      seed: () => const AiFoodieState(messages: fixedPriorMessages),
      act: (bloc) => bloc.add(const SendUserPrompt('第二句')),
      verify: (_) {
        final captured = verify(
          () => repository.askAssistant(
            '第二句',
            history: captureAny(named: 'history'),
            candidateRestaurants: any(named: 'candidateRestaurants'),
          ),
        ).captured;
        expect(captured.single, fixedPriorMessages);
      },
    );
  });
}
