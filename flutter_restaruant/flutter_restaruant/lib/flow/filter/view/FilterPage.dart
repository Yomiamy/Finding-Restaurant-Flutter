import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/model/FilterConfigs.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

class FilterPage extends StatefulWidget {
  static const ROUTE_NAME = "FilterPage";

  const FilterPage({Key? key}) : super(key: key);

  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {

  int _priceIndex = 0;
  DateTime _openAtDateTime = DateTime.now();
  int _sortingRuleIndex = 0;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Tuple2<FilterConfigs, dynamic>;
    FilterConfigs configs = args.item1;
    this._priceIndex = configs.priceIndex;
    this._openAtDateTime = configs.openAtDateTime;
    this._sortingRuleIndex = configs.sortingRuleIndex;

    return PlatformScaffold(
        appBar: PlatformAppBar(
            leading: PlatformIconButton(
                padding: EdgeInsets.all(0),
                onPressed: () => Navigator.of(context).pop(),
                materialIcon: Icon(Icons.arrow_back,
                    color: Color(UIConstants.BackBtnColor)),
                cupertinoIcon: Icon(CupertinoIcons.back,
                    color: Color(UIConstants.BackBtnColor))),
            trailingActions: [
              PlatformButton(
                  padding: EdgeInsets.all(0),
                  onPressed: () {
                    FilterConfigs configs = FilterConfigs.fromUI(priceIndex: this._priceIndex, openAtDate: this._openAtDateTime, sortingRuleIndex: this._sortingRuleIndex);
                    Tuple2<FilterConfigs, dynamic> result = Tuple2(configs, null);
                    Navigator.pop(context, result);
                  },
                  child: Text("套用",
                      style: TextStyle(
                          color: Colors.white, fontSize: Dimens.xhFontSize)))
            ],
            title: Text("過濾條件",
                style: TextStyle(
                    color: Colors.white, fontSize: Dimens.xxxhFontSize)),
            backgroundColor: Color(UIConstants.AppBarColor)),
        body: ListView(children: <Widget>[
          // Price level
          Padding(
              padding: EdgeInsets.only(left: 20, top: 15),
              child: Text("消費程度",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Dimens.xxxhFontSize))),
          this._createSegmentWidget(
              initValue: this._priceIndex,
              segmentItems: ['\$', '\$\$', '\$\$\$', '\$\$\$\$'],
              valueChange: (i) {
                this._priceIndex = i;
              }),

          // Business hour
          Padding(
              padding: EdgeInsets.only(left: 20, top: 15, right: 20),
              child: Text("營業時間",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Dimens.xxxhFontSize))),
          SizedBox(
            width: MediaQuery.of(context).size.width.toInt() - 20,
            height: 200,
            child: CupertinoDatePicker(
                initialDateTime: this._openAtDateTime,
                use24hFormat: true,
                mode: CupertinoDatePickerMode.dateAndTime,
                onDateTimeChanged: (dateTime) {
                  this._openAtDateTime = dateTime;
                })
          ),

          // Sorting rule
          Padding(
              padding: EdgeInsets.only(left: 20, top: 15),
              child: Text("排序依據",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Dimens.xxxhFontSize))),
          this._createSegmentWidget(
              initValue: this._sortingRuleIndex,
              segmentItems: ["最佳配對", '距離', '評分', '最多評論'],
              valueChange: (i) {
                this._sortingRuleIndex = i;
              })
        ]));
  }

  Widget _createSegmentWidget({required int initValue,
    required List<String> segmentItems,
    required ValueChanged<int> valueChange}) {

    Map<int, Widget> children = <int, Widget>{};

    for(int i = 0; i < segmentItems.length; i++) {
      children[i] = Text(segmentItems[i]);
    }
    return StatefulBuilder(
        builder: (context, _setState) => Padding(
            padding: EdgeInsets.only(left: 5, top: 15),
            child: CupertinoSegmentedControl<int>(
                groupValue: initValue,
                children: children,
                onValueChanged: (i) {
                  _setState(() {
                    initValue = i;
                    valueChange(i);
                  });
                })));
  }
}
