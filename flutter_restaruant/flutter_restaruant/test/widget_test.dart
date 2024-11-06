// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_restaruant/component/LoadingWidget.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  testWidgets('LoadingWidget Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(LoadingTestApp());

    //await tester.pumpAndSettle(Duration(seconds: 2));
    await tester.pump();

    // Verify that our counter starts at 0.
    expect(find.byType(LoadingWidget), findsNothing);
  });
}

class LoadingTestApp extends StatelessWidget {
  const LoadingTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(child: LoadingWidget())
    );
  }
}

