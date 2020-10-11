import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'flow/MainPage.dart';

void main() {
  runApp(FindingRestaruantApp());
}

class FindingRestaruantApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => PlatformApp(title:  "Find Restaurant", home: MainPage(title: "Find Restaurant"));
}


