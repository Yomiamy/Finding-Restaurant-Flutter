import 'dart:async';
import 'package:flutter/material.dart';
import '../../main/view/main_page.dart';
import '../../signinup/view/sign_in_page.dart';
import '../../../manager/sign_in_manager.dart';

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
        // 訪客已在前次啟動選擇跳過登入，直接進主畫面。
        final String routeName = SignInManager().isGuest
            ? MainPage.routeName
            : SignInPage.routeName;
        // ignore: unawaited_futures
        Navigator.of(context).pushReplacementNamed(routeName);
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
