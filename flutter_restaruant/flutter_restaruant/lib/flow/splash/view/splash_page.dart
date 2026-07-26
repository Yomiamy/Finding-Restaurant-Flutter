import 'dart:async';
import 'package:flutter/material.dart';
import '../../signinup/view/sign_in_page.dart';

class SplashPage extends StatefulWidget {
  static const routeName = '/';

  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      // Waiting building is finish and run.
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        // ignore: unawaited_futures
        Navigator.of(context).pushReplacementNamed(SignInPage.routeName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Image.asset(
      'images/launch_image.png',
      fit: BoxFit.fill,
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
    ));
  }
}
