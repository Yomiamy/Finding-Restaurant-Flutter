import 'package:flutter/material.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';

class RestaurantBusinessCell extends StatelessWidget {

  const RestaurantBusinessCell({Key? key = const Key("RestaurantBusinessCell")}) : super(key: key);

  Widget createBusinessTimeRow(String weedDay, String startTime, String endTime) => Padding(
      padding: EdgeInsets.only(top: 5),
      child: Stack(children: [
        Align(child: Text(weedDay), alignment: Alignment.centerLeft),
        Align(
            child: Text("$startTime - $endTime"),
            alignment: Alignment.centerRight)
      ]));

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Container(
              width: MediaQuery.of(context).size.width,
              child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.grey),
                  child: Center(
                      child: Text("營業時間",
                          style: TextStyle(
                              fontSize: Dimens.xhFontSize,
                              fontWeight: FontWeight.bold))))),
          Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                this.createBusinessTimeRow("星期一", "1700", "2200"),
                this.createBusinessTimeRow("星期二", "1700", "2200"),
                this.createBusinessTimeRow("星期三", "1700", "2200"),
                this.createBusinessTimeRow("星期四", "1700", "2200"),
                this.createBusinessTimeRow("星期五", "1700", "2200"),
                this.createBusinessTimeRow("星期六", "1700", "2200"),
                this.createBusinessTimeRow("星期日", "1700", "2200"),
              ]))
        ]),
      );
}
