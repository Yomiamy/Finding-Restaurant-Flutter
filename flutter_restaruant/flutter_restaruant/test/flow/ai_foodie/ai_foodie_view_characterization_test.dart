import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_restaruant/domain/domain_barrel.dart';
import 'package:flutter_restaruant/domain/entities/a2ui_fallback_strings.dart';
import 'package:flutter_restaruant/features/utils/utils_barrel.dart';
import 'package:flutter_restaruant/flow/ai_foodie/ai_foodie_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// 特性測試：AI 覓食畫布在「全缺值／全有值」下的顯示與互動。
/// 修改斷言的期望值＝行為改變，必須在 PR 中說明；替換測試替身或排版不受限制。
class _MockRepo extends Mock implements AiFoodieRepository {}

class _Harness {
  _Harness(this.repo);
  final _MockRepo repo;
  final routeArgs = <Object?>[];
}

Future<_Harness> _pump(
  WidgetTester tester,
  Map<String, Object?> messageJson,
) async {
  await tester.binding.setSurfaceSize(const Size(800, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final repo = _MockRepo();
  when(
    () => repo.getInitialSuggestions(),
  ).thenAnswer((_) async => [AiFoodieMessage.fromJson(messageJson)]);
  when(
    () => repo.askAssistant(
      any(),
      history: any(named: 'history'),
      candidateRestaurants: any(named: 'candidateRestaurants'),
    ),
  ).thenAnswer(
    (inv) async =>
        AiFoodieMessage.assistant(text: '回覆：${inv.positionalArguments.first}'),
  );
  final h = _Harness(repo);
  final bloc = AiFoodieBloc(repository: h.repo);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale('zh', 'TW'),
      onGenerateRoute: (settings) {
        h.routeArgs.add(settings.arguments);
        return MaterialPageRoute<void>(builder: (_) => const SizedBox());
      },
      home: Scaffold(body: AiFoodieSheet(bloc: bloc)),
    ),
  );
  await tester.pump();
  await tester.pump();
  return h;
}

RestaurantEntity _navigated(_Harness h) =>
    (h.routeArgs.last as Tuple2<RestaurantEntity, dynamic>).item1;

class _Data {
  static const Map<String, Object?> full = {
    'id': 'm1',
    'is_user': false,
    'text': '推薦如下',
    'created_at': '2026-09-24T12:00:00.000',
    'components': [
      {
        'component_type': 'comparison_matrix',
        'data': {
          'title': '精選對比',
          'items': [
            {
              'id': 'r1',
              'name': '野武士',
              'rating': 4,
              'price': '\$550',
              'highlights': ['串燒', '包廂', '深夜'],
              'address': '台北市中山區',
              'category': '日式',
              'image_url': 'https://img/1.jpg',
            },
          ],
        },
      },
      {
        'component_type': 'action_chip_group',
        'data': {
          'chips': [
            {
              'label': '找宵夜',
              'action': 'query',
              'payload': {'prompt': '深夜拉麵'},
            },
          ],
        },
      },
      {
        'component_type': 'decision_roulette',
        'data': {
          'title': '今晚吃啥',
          'options': ['A', 'B'],
        },
      },
      {'component_type': 'mystery', 'text': '降級文字'},
    ],
  };

  static const Map<String, Object?> missing = {
    'components': [
      {
        'component_type': 'comparison_matrix',
        'data': {
          'items': [<String, Object?>{}],
        },
      },
      {
        'component_type': 'action_chip_group',
        'data': {
          'chips': [
            {'label': '只有標籤', 'action': 'custom'},
          ],
        },
      },
      {
        'component_type': 'decision_roulette',
        'data': {
          'options': ['A', 'B'],
        },
      },
      {'component_type': 'mystery'},
    ],
  };
}

void main() {
  setUpAll(() async => S.load(const Locale('zh', 'TW')));

  group('全欄位有值', () {
    testWidgets('顯示', (tester) async {
      await _pump(tester, _Data.full);
      expect(find.text('推薦如下'), findsOneWidget);
      expect(find.text('精選對比'), findsOneWidget);
      expect(find.text('野武士'), findsOneWidget);
      expect(find.text('4.0'), findsOneWidget);
      expect(find.text('日式'), findsOneWidget);
      expect(find.text('\$550'), findsOneWidget);
      expect(find.text('串燒'), findsOneWidget);
      expect(find.text('包廂'), findsOneWidget);
      expect(find.text('深夜'), findsNothing);
      expect(find.text('台北市中山區'), findsOneWidget);
      expect(find.text('找宵夜'), findsOneWidget);
      expect(find.text('今晚吃啥'), findsOneWidget);
      expect(find.text('降級文字'), findsOneWidget);
    });

    testWidgets('點比較卡片 → 導航參數', (tester) async {
      final h = await _pump(tester, _Data.full);
      await tester.tap(find.text('野武士'));
      await tester.pump();
      final e = _navigated(h);
      expect(e.id, 'r1');
      expect(e.name, '野武士');
      expect(e.rating, 4.0);
      expect(e.price, '\$550');
      expect(e.imageUrl, 'https://img/1.jpg');
      expect(e.location?.address1, '台北市中山區');
    });

    testWidgets('點 query chip → 送出 prompt，history 為 entity', (tester) async {
      final h = await _pump(tester, _Data.full);
      await tester.tap(find.text('找宵夜'));
      await tester.pump();
      await tester.pump();
      expect(find.text('深夜拉麵'), findsOneWidget);
      // history 是送出前的 state.messages（entity），與重新解析的同一份 JSON 相等
      final captured = verify(
        () => h.repo.askAssistant(
          any(),
          history: captureAny(named: 'history'),
          candidateRestaurants: any(named: 'candidateRestaurants'),
        ),
      ).captured;
      expect(captured.single, [AiFoodieMessage.fromJson(_Data.full)]);
    });

    testWidgets('點轉盤按鈕 → 開啟轉盤並帶標題', (tester) async {
      await _pump(tester, _Data.full);
      await tester.tap(find.text('今晚吃啥'));
      await tester.pump();
      await tester.pump();
      expect(find.text('今晚吃啥'), findsNWidgets(2));
    });
  });

  group('全欄位缺值', () {
    testWidgets('顯示', (tester) async {
      await _pump(tester, _Data.missing);
      expect(
        find.text(A2UIFallbackStrings.comparisonMatrixTitle),
        findsOneWidget,
      );
      expect(find.text(A2UIFallbackStrings.comparisonItemName), findsOneWidget);
      expect(find.text('0.0'), findsOneWidget);
      expect(find.text('只有標籤'), findsOneWidget);
      expect(
        find.text(A2UIFallbackStrings.decisionRouletteTitle),
        findsOneWidget,
      );
      expect(find.text(A2UIFallbackStrings.unknownComponent), findsOneWidget);
      // 缺 is_user → 助理訊息：header 與訊息頭像各一個 auto_awesome
      expect(find.byIcon(Icons.auto_awesome), findsNWidgets(2));
    });

    testWidgets('點比較卡片 → 導航參數', (tester) async {
      final h = await _pump(tester, _Data.missing);
      await tester.tap(find.text(A2UIFallbackStrings.comparisonItemName));
      await tester.pump();
      final e = _navigated(h);
      expect(e.id, '');
      expect(e.name, A2UIFallbackStrings.comparisonItemName);
      expect(e.rating, 0.0);
      expect(e.price, isNull);
      expect(e.imageUrl, isNull);
      expect(e.location, isNull);
    });

    testWidgets('點轉盤按鈕 → 轉盤標題為預設', (tester) async {
      await _pump(tester, _Data.missing);
      await tester.tap(find.text(A2UIFallbackStrings.decisionRouletteTitle));
      await tester.pump();
      await tester.pump();
      expect(
        find.text(A2UIFallbackStrings.decisionRouletteTitle),
        findsNWidgets(2),
      );
    });

    testWidgets('點未知 action chip → 無動作', (tester) async {
      final h = await _pump(tester, _Data.missing);
      await tester.tap(find.text('只有標籤'));
      await tester.pump();
      verifyNever(
        () => h.repo.askAssistant(
          any(),
          history: any(named: 'history'),
          candidateRestaurants: any(named: 'candidateRestaurants'),
        ),
      );
    });
  });
}
