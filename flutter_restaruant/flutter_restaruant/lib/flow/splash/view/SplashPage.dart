import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/ad/InterstitialAD.dart';
import 'package:flutter_restaruant/component/ad/InterstitialADState.dart';
import 'package:flutter_restaruant/flow/main/view/MainPage.dart';
import 'package:flutter_restaruant/flow/signin/view/SignInPage.dart';
import 'package:flutter_restaruant/manager/GoogleSignInManager.dart';
import 'package:flutter_restaruant/utils/Constants.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SplashPage extends StatefulWidget {

  static const ROUTE_NAME = "/";

  const SplashPage();

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();

    // 全屏AD
    IntersitialAD(adState: InterstitialADState()).load();
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 10)).then((value) => Navigator.of(context).pushReplacementNamed(MainPage.ROUTE_NAME));

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
}
