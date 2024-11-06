import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {

  final String text;

  LoadingWidget({Key? key, this.text = "Loading..."}) : super(key: key);

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
