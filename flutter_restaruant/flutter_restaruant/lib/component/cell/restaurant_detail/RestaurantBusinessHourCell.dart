import 'package:flutter/material.dart';
import 'package:flutter_restaruant/model/YelpResaruantBusinessTime.dart';
import 'package:flutter_restaruant/model/YelpRestaurantHoursInfo.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';

class RestaurantBusinessHourCell extends StatelessWidget {

  final List<Widget> _businessTimeWidgets = <Widget>[];

  RestaurantBusinessHourCell({Key? key = const Key("RestaurantBusinessCell"), required List<YelpResaruantBusinessTime> businessTimeInfos}): super(key: key) {
    this._initBusinessTimeWidgets(businessTimeInfos);
  }

  void _initBusinessTimeWidgets(List<YelpResaruantBusinessTime> businessTimeInfos) {
    Map<int, List<Widget>> businessTimeWidgetMap = <int, List<Widget>>{};

    businessTimeInfos.forEach((businessTimeInfo) {
      int day = businessTimeInfo.day ?? 0;
      String dayStr = businessTimeInfo.dayStr;
      String start = businessTimeInfo.start ?? "";
      String end = businessTimeInfo.end ?? "";
      Widget businessTimeWidget;
      List<Widget> businessTimeWidgets;

      if(!businessTimeWidgetMap.containsKey(businessTimeInfo.day)) {
        businessTimeWidgets = <Widget>[];
        businessTimeWidget = this._createBusinessTimeRow(dayStr, start, end);
      } else {
        businessTimeWidgets = businessTimeWidgetMap[day]!;
        businessTimeWidget = this._createBusinessTimeRow("", start, end);
      }
      businessTimeWidgets.add(businessTimeWidget);
      businessTimeWidgetMap[day] = businessTimeWidgets;
    });

    businessTimeWidgetMap.values.forEach((businessTimeWidgets) => this._businessTimeWidgets.addAll(businessTimeWidgets));
  }

  Widget _createBusinessTimeRow(String weedDay, String startTime, String endTime) => Padding(
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
              child: Column(mainAxisSize: MainAxisSize.min,
                  children: this._businessTimeWidgets
              ))
        ]),
      );
}
