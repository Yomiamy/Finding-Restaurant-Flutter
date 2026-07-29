import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String text;

  const LoadingWidget({super.key, this.text = 'Loading...'});

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text(text)
      ]);
}
