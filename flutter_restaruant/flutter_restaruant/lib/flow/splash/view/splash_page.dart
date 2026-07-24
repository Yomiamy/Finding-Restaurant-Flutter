import 'package:flutter/material.dart';
import 'package:flutter_restaruant/flow/signinup/view/sign_in_page.dart';

class SplashPage extends StatefulWidget {
  static const ROUTE_NAME = "/";

  const SplashPage();

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // Waiting building is finish and run.
      Future.delayed(Duration(seconds: 3)).then((value) =>
          Navigator.of(context).pushReplacementNamed(SignInPage.ROUTE_NAME));
    });

    return Scaffold(
        body: Container(
            child: Image.asset(
      "images/launch_image.png",
      fit: BoxFit.fill,
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
    )));
  }
}
