import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/flow/main/view/MainPage.dart';
import 'package:flutter_restaruant/flow/signin/view/SignInPage.dart';
import 'package:flutter_restaruant/manager/GoogleSignInManager.dart';

class SplashPage extends StatefulWidget {

  static const ROUTE_NAME = "/";

  const SplashPage();

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2)).then((value) => Navigator.of(context).pushReplacementNamed(SignInPage.ROUTE_NAME));

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
