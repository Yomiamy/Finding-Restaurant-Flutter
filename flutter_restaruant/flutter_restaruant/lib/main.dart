import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'component/ad/BannerADState.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import 'firebase_options.dart';
import 'routes/RoutesTable.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'utils/UIConstants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final initFuture = MobileAds.instance.initialize();
  final adState = BannerADState(initFuture);
  runApp(Provider.value(
    value: adState,
    builder: (context, child) => FindingRestaruantApp()
  ));
}

class FindingRestaruantApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => PlatformApp(
      title:  UIConstants.APP_TITLE,
      routes: ROUTES_TABLE
  );
}


