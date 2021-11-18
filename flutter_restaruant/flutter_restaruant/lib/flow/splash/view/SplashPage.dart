import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class SplashPage extends StatefulWidget {

  static const ROUTE_NAME = "/";

  const SplashPage();

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  Widget build(BuildContext context) => PlatformScaffold(
    body: Container(
        child: Image.asset(
        "images/launch_image.png",
        fit: BoxFit.fill,
        height: double.infinity,
        width: double.infinity,
      ))
  );
}
