import 'dart:async';
import 'dart:ui' as ui;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'features/foundation/constants/constants_barrel.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'component/ad/ad_barrel.dart';
import 'di/di_barrel.dart';
import 'firebase_options.dart';
import 'generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'manager/manager_barrel.dart';
import 'routes/routes_barrel.dart';
import 'features/foundation/style/style_barrel.dart';

// For FCM onMessageOpenedApp to open specific page
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupInjection();

  // MobileAds init
  final initFuture = MobileAds.instance.initialize();
  getIt.registerSingleton<BannerADState>(BannerADState(initFuture));

  Future.wait([
    Constants.init(),
    // Firebase Init
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    S.load(ui.PlatformDispatcher.instance.locale),
    // 於 runApp 前載入，使 isGuest 可被 UI 同步查詢
    SignInManager().loadPrefs(),
    // ignore: unawaited_futures
  ]).then((_) {
    FcmManager().init();

    runApp(const FindingRestaruantApp());
  });
}

class FindingRestaruantApp extends StatelessWidget {
  const FindingRestaruantApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => PlatformApp(
      navigatorKey: navigatorKey,
      locale: const Locale('zh', 'TW'),
      localizationsDelegates: const [
        S.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      debugShowCheckedModeBanner: false,
      title: UIConstants.appTitle,
      routes: routesTable,
      // 不做深色模式（darkTheme 指向同一份 light），系統切深色時 app 外觀
      // 維持不變，避免內容淺色底卻配到深色模式的系統 UI。
      material: (_, __) => MaterialAppData(
            theme: AppTheme.materialLight,
            darkTheme: AppTheme.materialLight,
            themeMode: ThemeMode.light,
          ),
      // iOS 走 CupertinoApp 分支，`material:` 不生效。CupertinoApp 自身的
      // brightness 預設會跟隨 MediaQuery.platformBrightnessOf，導致系統深色
      // 模式下狀態列圖示轉白、與淺色內容相衝，故在此明確鎖為 light。
      cupertino: (_, __) => CupertinoAppData(
            theme: AppTheme.cupertinoLight,
          ),
      // 兩個平台的 Material widget 都靠這層解析到同一份 ThemeData
      // （iOS 沒有 MaterialApp 可繼承，Android 則是與內層 Theme 重疊但無害）。
      builder: (_, child) => Theme(
            data: AppTheme.materialLight,
            child: child ?? const SizedBox.shrink(),
          ));
}
