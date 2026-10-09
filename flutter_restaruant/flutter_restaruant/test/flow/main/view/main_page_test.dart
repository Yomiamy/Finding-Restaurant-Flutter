import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_restaruant/component/component_barrel.dart';
import 'package:flutter_restaruant/di/di_barrel.dart';
import 'package:flutter_restaruant/flow/main/bloc/bloc_barrel.dart';
import 'package:flutter_restaruant/flow/main/view/view_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 只記錄派發事件、不執行任何邏輯的 MainBloc。
///
/// bloc 的 `add()` 在 debug 下斷言 handler 已註冊，故以 `on<MainEvent>` 吃掉
/// 所有事件（geolocator／FCM／Yelp 皆不會被觸及）；`onEvent` 於 `add()` 內
/// 同步呼叫，記錄不需等待事件迴圈。
class _RecordingMainBloc extends Bloc<MainEvent, MainState>
    implements MainBloc {
  _RecordingMainBloc() : super(const MainInitial()) {
    on<MainEvent>((_, __) {});
  }

  final List<Type> dispatched = [];

  @override
  void onEvent(MainEvent event) {
    super.onEvent(event);
    dispatched.add(event.runtimeType);
  }
}

void main() {
  Future<_RecordingMainBloc> pumpMainPage(WidgetTester tester) async {
    final bloc = _RecordingMainBloc();
    // 不可在測試本體 await close()：已註冊 handler 的 bloc 在 fake async 下會卡住。
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.delegate.supportedLocales,
        home: BlocProvider<MainBloc>.value(
          value: bloc,
          child: const MainPage(),
        ),
      ),
    );
    return bloc;
  }

  testWidgets('macOS：不取 BannerADState、廣告條不佔位、不派發 NotificationSetup', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      // 刻意不註冊 BannerADState：MainPage 若仍向 getIt 取用會拋 StateError
      // ——main.dart 在同一平台略過了註冊（規格 §5.3）。
      final bloc = await pumpMainPage(tester);

      // initState 先於 build：即使 build 拋錯，派發紀錄仍可斷言。
      expect(bloc.dispatched, [FetchSearchInfo]);
      expect(tester.takeException(), isNull);
      expect(find.byType(BannerAD), findsNothing);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).bottomNavigationBar,
        isNull,
      );

      await tester.pumpWidget(const SizedBox());
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('android：BannerAD 照常、NotificationSetup 照常先於 FetchSearchInfo', (
    tester,
  ) async {
    // 永不完成的初始化：BannerAD 停在佔位狀態，不碰 AdMob platform channel。
    getIt.registerSingleton<BannerADState>(
      BannerADState(Completer<InitializationStatus>().future),
    );
    addTearDown(getIt.reset);

    final bloc = await pumpMainPage(tester);

    expect(bloc.dispatched, [NotificationSetup, FetchSearchInfo]);
    expect(find.byType(BannerAD), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
