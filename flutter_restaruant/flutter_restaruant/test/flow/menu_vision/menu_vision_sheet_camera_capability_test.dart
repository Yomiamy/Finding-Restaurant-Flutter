import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_restaruant/domain/domain_barrel.dart';
import 'package:flutter_restaruant/flow/menu_vision/menu_vision_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// 鎖住 A-9.6 AC-9：無相機能力的平台（macOS）不出現任何拍照入口、
/// 也不自動觸發相機；android 對照組確認行動版取消畫面的拍照入口仍在。
class _MockRepo extends Mock implements MenuVisionRepository {}

class _Data {
  static final pickFailure = Exception('mock gallery failure');
}

Future<void> _pumpSheet(
  WidgetTester tester,
  MenuVisionRepository repo, {
  bool autoStartCapture = false,
}) async {
  final bloc = MenuVisionBloc(repository: repo);
  // 不可在測試本體 await close()：fake async 下會卡住（A-9.2 計畫 §0）。
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MenuVisionSheet(bloc: bloc, autoStartCapture: autoStartCapture),
      ),
    ),
  );
}

/// 讓 bloc 的非同步 handler 跑完（沿用既有 Menu Vision 測試的 runAsync 寫法）。
Future<void> _settleBloc(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
}

Future<void> _tapGallery(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('gallery_pick_button')));
  await _settleBloc(tester);
}

void main() {
  setUpAll(() async {
    await S.load(const Locale('zh', 'TW'));
  });

  group('macOS 無相機能力', () {
    testWidgets('初始畫面與標題列：無拍照入口，相簿與關閉仍在', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await _pumpSheet(tester, _MockRepo());

        expect(find.byKey(const Key('take_photo_button')), findsNothing);
        expect(find.byKey(const Key('gallery_pick_button')), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt_outlined), findsNothing);
        expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('取消畫面：無拍照按鈕，相簿按鈕仍在', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final repo = _MockRepo();
        when(() => repo.pickImageFromGallery()).thenAnswer((_) async => null);
        await _pumpSheet(tester, repo);
        await _tapGallery(tester);

        expect(
          find.text(S.current.menu_vision_cancelled_title),
          findsOneWidget,
        );
        expect(
          find.text(S.current.menu_vision_btn_take_photo_short),
          findsNothing,
        );
        expect(find.byIcon(Icons.camera_alt), findsNothing);
        expect(
          find.text(S.current.menu_vision_btn_gallery_short),
          findsOneWidget,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('失敗畫面：無「重新拍攝」，「相簿重選」仍在', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final repo = _MockRepo();
        when(() => repo.pickImageFromGallery()).thenThrow(_Data.pickFailure);
        await _pumpSheet(tester, repo);
        await _tapGallery(tester);

        expect(find.text(S.current.menu_vision_failure_title), findsOneWidget);
        expect(find.text(S.current.menu_vision_btn_retake), findsNothing);
        expect(find.byIcon(Icons.camera_alt), findsNothing);
        expect(
          find.text(S.current.menu_vision_btn_reselect_gallery),
          findsOneWidget,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('autoStartCapture: true 不觸發相機', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        final repo = _MockRepo();
        when(() => repo.captureImage()).thenAnswer((_) async => null);
        await _pumpSheet(tester, repo, autoStartCapture: true);
        await _settleBloc(tester);

        verifyNever(() => repo.captureImage());
        expect(find.byKey(const Key('gallery_pick_button')), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  testWidgets('android 對照組：取消畫面仍有拍照與相簿按鈕', (tester) async {
    final repo = _MockRepo();
    when(() => repo.pickImageFromGallery()).thenAnswer((_) async => null);
    await _pumpSheet(tester, repo);
    await _tapGallery(tester);

    expect(find.text(S.current.menu_vision_cancelled_title), findsOneWidget);
    expect(
      find.text(S.current.menu_vision_btn_take_photo_short),
      findsOneWidget,
    );
    expect(find.text(S.current.menu_vision_btn_gallery_short), findsOneWidget);
  });
}
