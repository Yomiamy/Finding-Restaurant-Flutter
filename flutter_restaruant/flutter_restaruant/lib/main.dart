import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/utils/Constants.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'component/ad/BannerADState.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'manager/FcmManager.dart';
import 'routes/RoutesTable.dart';

// For FCM onMessageOpenedApp to open specific page
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // MobileAds init
  final initFuture = MobileAds.instance.initialize();
  final adState = BannerADState(initFuture);
  // GoogleMap init
  if (Platform.isAndroid) {
    AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
  }

  Future.wait([
    Constants.init(),
    // Firebase Init
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    )
  ]).then((_) {
    FcmManager().init();

    runApp(Provider.value(value: adState, builder: (context, child) => FindingRestaruantApp()));
  });
}

class FindingRestaruantApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => PlatformApp(
      navigatorKey: navigatorKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      title: UIConstants.APP_TITLE,
      routes: ROUTES_TABLE);
}
