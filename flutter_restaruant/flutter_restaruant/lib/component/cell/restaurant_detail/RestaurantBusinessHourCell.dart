import 'package:flutter/material.dart';
import 'package:flutter_restaruant/model/YelpResaruantBusinessTime.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

class RestaurantBusinessHourCell extends StatelessWidget {

  final List<Widget> _businessTimeWidgets = <Widget>[];

  RestaurantBusinessHourCell({Key? key = const Key("RestaurantBusinessCell"), required List<YelpResaruantBusinessTime> businessTimeInfos}): super(key: key) {
    this._initBusinessTimeWidgets(businessTimeInfos);
  }

  void _initBusinessTimeWidgets(List<YelpResaruantBusinessTime> businessTimeInfos) {
    Map<int, List<Widget>> businessTimeWidgetMap = <int, List<Widget>>{};
    int nowWeekDay = DateTime.now().weekday;

    businessTimeInfos.forEach((businessTimeInfo) {
      int yelpWeekDay = businessTimeInfo.day ?? 0;
      String dayStr = businessTimeInfo.dayStr;
      String start = businessTimeInfo.start ?? "";
      String end = businessTimeInfo.end ?? "";
      bool isToday = businessTimeInfo.isNowWeedDayMatchYelpWeekDay(nowWeekDay: nowWeekDay, yelpWeekDay: yelpWeekDay);
      Widget businessTimeWidget;
      List<Widget> businessTimeWidgets;

      if(!businessTimeWidgetMap.containsKey(businessTimeInfo.day)) {
        businessTimeWidgets = <Widget>[];
        businessTimeWidget = this._createBusinessTimeRow(isToday, dayStr, start, end);
      } else {
        businessTimeWidgets = businessTimeWidgetMap[yelpWeekDay]!;
        businessTimeWidget = this._createBusinessTimeRow(isToday, "", start, end);
      }
      businessTimeWidgets.add(businessTimeWidget);
      businessTimeWidgetMap[yelpWeekDay] = businessTimeWidgets;
    });

    businessTimeWidgetMap.values.forEach((businessTimeWidgets) => this._businessTimeWidgets.addAll(businessTimeWidgets));
  }

  Widget _createBusinessTimeRow(bool isToday, String weekDay, String startTime, String endTime) => Padding(
      padding: EdgeInsets.only(top: 5),
      child: Stack(children: [
        Align(child: Text(weekDay, style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal)), alignment: Alignment.centerLeft),
        Align(
            child: Text("$startTime - $endTime", style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
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
                      child: Text(AppLocalizations?.of(context)?.business_hour ?? "" ,
                          style: TextStyle(
                              fontSize: UIConstants.xhFontSize,
                              fontWeight: FontWeight.bold))))),
          Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Column(mainAxisSize: MainAxisSize.min,
                  children: this._businessTimeWidgets
              ))
        ]),
      );
}
