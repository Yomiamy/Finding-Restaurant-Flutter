import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/ad/AppLifecycleReactor.dart';
import 'package:flutter_restaruant/component/ad/AppOpenAD.dart';
import 'package:flutter_restaruant/component/ad/AppOpenAdState.dart';
import 'package:flutter_restaruant/flow/main/view/MainPage.dart';

class SplashPage extends StatefulWidget {

  static const ROUTE_NAME = "/";

  const SplashPage();

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> implements AppOpenADEvent {

  late AppLifecycleReactor _appLifecycleReactor;

  @override
  void initState() {
    super.initState();

    // App Open Ad
    AppOpenAD appOpenAD = AppOpenAD(adState: AppOpenADState(appOpenADEventListener: this))..loadAd();
    _appLifecycleReactor = AppLifecycleReactor(appOpenAd: appOpenAD);
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
        body: Container(
            child: Image.asset(
              "images/launch_image.png",
              fit: BoxFit.fill,
              height: double.infinity,
              width: double.infinity,
            ))
    );
  }

  /// AppOpenADEvent
  @override
  void onFailedToShow() {
    Navigator.of(context).pushReplacementNamed(MainPage.ROUTE_NAME);
  }

  @override
  void onAdDismissed() {
    Navigator.of(context).pushReplacementNamed(MainPage.ROUTE_NAME);
  }
}
