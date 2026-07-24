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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      // Waiting building is finish and run.
      await Future.delayed(Duration(seconds: 3));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(SignInPage.ROUTE_NAME);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
