import 'package:flutter/material.dart';
import 'package:flutter_restaruant/component/PlatformWidget.dart';

class LoadingWidget extends StatelessWidget {

  final String text;

  const LoadingWidget({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(this.text)
          ]
      );
}
