import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../main/view/view_barrel.dart';
import '../../signinup/view/view_barrel.dart';
import '../../../di/di_barrel.dart';
import '../../../manager/manager_barrel.dart';

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
      if (!mounted) return;

      // 訪客已在前次啟動選擇跳過登入，直接進主畫面。
      final String routeName = SignInManager().isGuest
          ? MainPage.routeName
          : SignInPage.routeName;
      // ignore: unawaited_futures
      Navigator.of(context).pushReplacementNamed(routeName);

      // 與 5 連點喚起手勢並存的第二進入點：常駐 FAB。此 context 來自
      // SplashPage 自身（已在 Navigator/Overlay 之下的路由 widget），
      // 與 main.dart builder 傳入的外層 context 不同，attach() 找得到
      // Overlay。
      if (!kDebugMode) return;
      inspector?.attach(context: context);
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
      ),
    );
  }
}
