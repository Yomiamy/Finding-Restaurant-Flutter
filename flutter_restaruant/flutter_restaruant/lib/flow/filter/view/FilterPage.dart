import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
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

  late void Function(int, int, int) _applyCallback;
  late int _priceLevelIndex = 0;
  late int _sortingRulIndex = 0;
  late int _businessTime = DateTime.now().millisecond;


  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Tuple4<int, int, int, void Function(int, int, int)>;
    this._priceLevelIndex = args.item1;
    this._sortingRulIndex = args.item2;
    this._businessTime = args.item3;
    this._applyCallback = args.item4;

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
                    this._applyCallback(this._priceLevelIndex, this._sortingRulIndex, this._businessTime);
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
              initValue: this._priceLevelIndex,
              segmentItems: ['\$', '\$\$', '\$\$\$', '\$\$\$\$'],
              valueChange: (i) {
                this._priceLevelIndex = i;
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
                use24hFormat: true,
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: DateTime.now(),
                onDateTimeChanged: (dateTime) {
                  this._businessTime = DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.second).millisecondsSinceEpoch;
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
              initValue: this._sortingRulIndex,
              segmentItems: ["最佳配對", '距離', '評分', '最多評論'],
              valueChange: (i) {
                this._sortingRulIndex = i;
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
