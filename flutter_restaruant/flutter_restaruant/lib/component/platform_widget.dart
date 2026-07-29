import 'package:flutter/material.dart';
import 'dart:io';

abstract class PlatformWidget<I extends Widget, A extends Widget>
    extends StatelessWidget {
  const PlatformWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return createAndroidWidget(context);
    } else if (Platform.isIOS) {
      return createIosWidget(context);
    }
    return Container();
  }

  I createIosWidget(BuildContext context);
  A createAndroidWidget(BuildContext context);
}
