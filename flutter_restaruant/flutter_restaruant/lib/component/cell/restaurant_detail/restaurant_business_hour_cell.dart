import 'package:flutter/material.dart';
import '../../../domain/entities/restaurant_business_time_entity.dart';
import '../../../generated/l10n.dart';
import '../../../features/foundation/style/style.dart';
import '../../../features/foundation/constants/app_constants.dart';

class RestaurantBusinessHourCell extends StatelessWidget {
  final List<Widget> _businessTimeWidgets = <Widget>[];

  RestaurantBusinessHourCell(
      {super.key = const Key('RestaurantBusinessCell'),
      required List<RestaurantBusinessTimeEntity> businessTimeInfos}) {
    _initBusinessTimeWidgets(businessTimeInfos);
  }

  void _initBusinessTimeWidgets(
      List<RestaurantBusinessTimeEntity> businessTimeInfos) {
    Map<int, List<Widget>> businessTimeWidgetMap = <int, List<Widget>>{};
    int nowWeekDay = DateTime.now().weekday;

    for (var businessTimeInfo in businessTimeInfos) {
      int yelpWeekDay = businessTimeInfo.day ?? 0;
      String dayStr = businessTimeInfo.dayStr;
      String start = businessTimeInfo.start ?? '';
      String end = businessTimeInfo.end ?? '';
      bool isToday = (nowWeekDay - 1) == yelpWeekDay;
      Widget businessTimeWidget;
      List<Widget> businessTimeWidgets;

      if (!businessTimeWidgetMap.containsKey(yelpWeekDay)) {
        businessTimeWidgets = <Widget>[];
        businessTimeWidget =
            _createBusinessTimeRow(isToday, dayStr, start, end);
      } else {
        businessTimeWidgets = businessTimeWidgetMap[yelpWeekDay]!;
        businessTimeWidget = _createBusinessTimeRow(isToday, '', start, end);
      }
      businessTimeWidgets.add(businessTimeWidget);
      businessTimeWidgetMap[yelpWeekDay] = businessTimeWidgets;
    }

    for (var businessTimeWidgets in businessTimeWidgetMap.values) {
      _businessTimeWidgets.addAll(businessTimeWidgets);
    }
  }

  Widget _createBusinessTimeRow(
          bool isToday, String weekDay, String startTime, String endTime) =>
      Padding(
          padding: const EdgeInsets.only(top: Sizes.space5),
          child: Stack(children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text(weekDay,
                    style: TextStyle(
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal))),
            Align(
                alignment: Alignment.centerRight,
                child: Text('$startTime - $endTime',
                    style: TextStyle(
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal)))
          ]));

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Sizes.space10),
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          SizedBox(
              width: MediaQuery.of(context).size.width,
              child: DecoratedBox(
                  decoration: const BoxDecoration(color: Colors.grey),
                  child: Center(
                      child: Text(S.current.business_hour,
                          style: const TextStyle(
                              fontSize: UIConstants.xhFontSize,
                              fontWeight: FontWeight.bold))))),
          Padding(
              padding: const EdgeInsets.only(
                  left: Sizes.space10, right: Sizes.space10),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _businessTimeWidgets))
        ]),
      );
}
