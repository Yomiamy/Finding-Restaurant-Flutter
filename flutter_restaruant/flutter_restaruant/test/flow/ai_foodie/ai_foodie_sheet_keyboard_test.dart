import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_restaruant/domain/domain_barrel.dart';
import 'package:flutter_restaruant/features/foundation/style/app_scroll_behavior.dart';
import 'package:flutter_restaruant/flow/ai_foodie/ai_foodie_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AiFoodieRepository {}

Widget _buildTestApp(AiFoodieBloc bloc) {
  return MaterialApp(
    scrollBehavior: const AppScrollBehavior(),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    locale: const Locale('zh', 'TW'),
    home: Scaffold(body: AiFoodieSheet(bloc: bloc)),
  );
}

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
      (inv) async => AiFoodieMessage.assistant(
        text: '回覆：${inv.positionalArguments.first}',
      ),
    );

    final bloc = AiFoodieBloc(repository: repo);
    addTearDown(bloc.close);

    await tester.pumpWidget(_buildTestApp(bloc));
    await tester.pump();
    await tester.pump();

    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    await tester.enterText(textFieldFinder, '想找拉麵');
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();

    verify(
      () => repo.askAssistant(
        '想找拉麵',
        history: any(named: 'history'),
        candidateRestaurants: any(named: 'candidateRestaurants'),
      ),
    ).called(1);
  });

  testWidgets(
    'AiFoodieSheet: pressing numpadEnter sends the message to bloc/repo',
    (tester) async {
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
        (inv) async => AiFoodieMessage.assistant(
          text: '回覆：${inv.positionalArguments.first}',
        ),
      );

      final bloc = AiFoodieBloc(repository: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();
      await tester.pump();

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '想吃火鍋');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      await tester.pump();
      await tester.pump();

      verify(
        () => repo.askAssistant(
          '想吃火鍋',
          history: any(named: 'history'),
          candidateRestaurants: any(named: 'candidateRestaurants'),
        ),
      ).called(1);
    },
  );

  testWidgets(
    'AiFoodieSheet: pressing Shift+Enter does not send or clear the draft',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _MockRepo();
      when(
        () => repo.getInitialSuggestions(),
      ).thenAnswer((_) async => [AiFoodieMessage.assistant(text: '哈囉')]);

      final bloc = AiFoodieBloc(repository: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();
      await tester.pump();

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '第一行');
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, '第一行');
      verifyNever(
        () => repo.askAssistant(
          any(),
          history: any(named: 'history'),
          candidateRestaurants: any(named: 'candidateRestaurants'),
        ),
      );
    },
  );

  testWidgets(
    'AiFoodieSheet: pressing Enter while loading preserves draft without sending',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final completer = Completer<List<AiFoodieMessage>>();
      final repo = _MockRepo();
      when(
        () => repo.getInitialSuggestions(),
      ).thenAnswer((_) => completer.future);

      final bloc = AiFoodieBloc(repository: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();

      expect(bloc.state.isLoading, isTrue);

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '載入中輸入的草稿');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, '載入中輸入的草稿');
      verifyNever(
        () => repo.askAssistant(
          any(),
          history: any(named: 'history'),
          candidateRestaurants: any(named: 'candidateRestaurants'),
        ),
      );

      completer.complete([AiFoodieMessage.assistant(text: '哈囉')]);
      await tester.pump();
    },
  );

  testWidgets(
    'AiFoodieSheet: pressing Enter during IME composing preserves composing text without sending',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _MockRepo();
      when(
        () => repo.getInitialSuggestions(),
      ).thenAnswer((_) async => [AiFoodieMessage.assistant(text: '哈囉')]);

      final bloc = AiFoodieBloc(repository: repo);
      addTearDown(bloc.close);

      await tester.pumpWidget(_buildTestApp(bloc));
      await tester.pump();
      await tester.pump();

      final textFieldFinder = find.byType(TextField);
      await tester.tap(textFieldFinder);
      await tester.pump();

      final textField = tester.widget<TextField>(textFieldFinder);
      textField.controller!.value = const TextEditingValue(
        text: '拉麵',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      );
      await tester.pump();

      expect(textField.controller!.value.isComposingRangeValid, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(textField.controller!.text, '拉麵');
      verifyNever(
        () => repo.askAssistant(
          any(),
          history: any(named: 'history'),
          candidateRestaurants: any(named: 'candidateRestaurants'),
        ),
      );
    },
  );

  testWidgets(
    'AiFoodieSheet: textInputAction is newline on Windows and send on macOS',
    (tester) async {
      final repo = _MockRepo();
      when(() => repo.getInitialSuggestions()).thenAnswer((_) async => []);

      Widget buildSheet() {
        final bloc = AiFoodieBloc(repository: repo);
        addTearDown(bloc.close);
        return _buildTestApp(bloc);
      }

      try {
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
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'AiFoodieSheet: mouse drag across TextField under AppScrollBehavior selects text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _MockRepo();
      when(() => repo.getInitialSuggestions()).thenAnswer((_) async => []);

      final bloc = AiFoodieBloc(repository: repo);
      addTearDown(bloc.close);

      try {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        await tester.pumpWidget(_buildTestApp(bloc));
        await tester.pump();
        await tester.pump();

        final textFieldFinder = find.byType(TextField);
        await tester.enterText(
          textFieldFinder,
          'Select this desktop prompt text with mouse drag',
        );
        await tester.pump();

        final editableFinder = find.byType(EditableText);
        final topLeft = tester.getTopLeft(editableFinder);
        final start = topLeft + const Offset(10, 10);
        final end = topLeft + const Offset(180, 10);

        final gesture = await tester.startGesture(
          start,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump();
        await gesture.moveTo(end);
        await tester.pump();
        await gesture.up();
        await tester.pump();

        final textField = tester.widget<TextField>(textFieldFinder);
        final selection = textField.controller!.selection;
        expect(selection.isCollapsed, isFalse);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
