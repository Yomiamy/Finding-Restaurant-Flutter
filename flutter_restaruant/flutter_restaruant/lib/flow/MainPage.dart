import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class MainPage extends StatefulWidget {
  final String title;
  final List<String> _words = [
    '1 abacus',
    '2 abdomen',
    '3 abdominal',
    '4 abide',
    '5 abiding',
    '6 ability',
    '7 ablaze',
    '8 able',
    '9 abnormal',
    '10 abrasion',
    '11 abrasive',
    '12 abreast',
    '13 abridge',
    '14 abroad',
    '15 abruptly',
    '16 absence',
    '17 absentee',
    '18 absently',
    '19 absinthe',
    '20 absolute',
    '21 absolve',
    '22 abstain',
    '23 abstract',
    '24 absurd',
    '25 accent',
    '26 acclaim',
    '27 acclimate'
  ];

  MainPage({Key key, this.title}) : super(key: key);

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) => PlatformScaffold(
        appBar: PlatformAppBar(
            title: PlatformText(this.widget.title,
                style: TextStyle(color: Colors.white, fontSize: 20.0)),
            backgroundColor: Color(0xffd84a20)),
        body: ListView(
          children: this
              .widget
              ._words
              .map((text) =>
                  Container(padding: EdgeInsets.all(16), child: Text(text)))
              .toList(),
        ),
      );
}
