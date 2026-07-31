import 'dart:async';
import 'dart:ui' as ui;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'utils/constants.dart';
import 'utils/ui_constants.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'component/ad/banner_ad_state.dart';
import 'di/injection.dart';
import 'firebase_options.dart';
import 'generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'manager/fcm_manager.dart';
import 'manager/sign_in_manager.dart';
import 'routes/routes_table.dart';
import 'theme/app_theme.dart';

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
      material: (_, __) => MaterialAppData(theme: AppTheme.light),
      // iOS 走 CupertinoApp 分支，`material:` 不生效；此處補上 Theme
      // 讓兩個平台的 Material widget 都能解析到同一份 ThemeData。
      builder: (_, child) => Theme(
            data: AppTheme.light,
            child: child ?? const SizedBox.shrink(),
          ));
}
