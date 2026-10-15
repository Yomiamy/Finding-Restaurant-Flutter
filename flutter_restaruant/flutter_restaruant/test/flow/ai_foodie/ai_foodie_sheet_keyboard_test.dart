import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_restaruant/domain/domain_barrel.dart';
import 'package:flutter_restaruant/flow/ai_foodie/ai_foodie_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AiFoodieRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const <AiFoodieMessage>[]);
  });

  testWidgets('AiFoodieSheet: pressing Enter sends the message to bloc/repo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = _MockRepo();
    when(
      () => repo.getInitialSuggestions(),
    ).thenAnswer((_) async => [AiFoodieMessage.assistant(text: '哈囉')]);
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

    final bloc = AiFoodieBloc(repository: repo);
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
        home: Scaffold(body: AiFoodieSheet(bloc: bloc)),
      ),
    );
    await tester.pump();
    await tester.pump();

    // 找到輸入框
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    // 輸入文字
    await tester.enterText(textFieldFinder, '想找拉麵');
    await tester.pump();

    // 模擬按下實體鍵盤 Enter
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();

    // 驗證 askAssistant 收到發送請求
    verify(
      () => repo.askAssistant(
        '想找拉麵',
        history: any(named: 'history'),
        candidateRestaurants: any(named: 'candidateRestaurants'),
      ),
    ).called(1);
  });

  testWidgets('AiFoodieSheet: textInputAction is newline on Windows and send on macOS', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(
      () => repo.getInitialSuggestions(),
    ).thenAnswer((_) async => []);

    Widget buildSheet() => MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale('zh', 'TW'),
      home: Scaffold(body: AiFoodieSheet(bloc: AiFoodieBloc(repository: repo))),
    );

    // Test Windows
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await tester.pumpWidget(buildSheet());
    await tester.pump();
    final winTextField = tester.widget<TextField>(find.byType(TextField));
    expect(winTextField.textInputAction, TextInputAction.newline);

    // Test macOS
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await tester.pumpWidget(buildSheet());
    await tester.pump();
    final macTextField = tester.widget<TextField>(find.byType(TextField));
    expect(macTextField.textInputAction, TextInputAction.send);

    debugDefaultTargetPlatformOverride = null;
  });
}
