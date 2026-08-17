import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../../../model/model_barrel.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../../features/foundation/constants/constants_barrel.dart';
import '../../../generated/l10n.dart';
import '../../../features/foundation/style/style_barrel.dart';

class FilterPage extends StatefulWidget {
  static const routeName = '/FilterPage';

  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  int _priceIndex = 0;
  DateTime _openAtDateTime = DateTime.now();
  int _sortByIndex = 0;

  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args =
          ModalRoute.of(context)!.settings.arguments
              as Tuple2<FilterConfigs, dynamic>;
      final configs = args.item1;
      _priceIndex = configs.priceIndex;
      _openAtDateTime = configs.openAtDateTime;
      _sortByIndex = configs.sortByIndex;
      _isInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: PlatformIconButton(
          padding: const EdgeInsets.all(ThemeSize.zero),
          onPressed: () => Navigator.of(context).pop(),
          materialIcon: const Icon(Icons.arrow_back, color: ThemeColor.backBtn),
          cupertinoIcon: const Icon(
            CupertinoIcons.back,
            color: ThemeColor.backBtn,
          ),
        ),
        actions: [
          PlatformElevatedButton(
            color: ThemeColor.appPrimary,
            padding: const EdgeInsets.all(ThemeSize.zero),
            onPressed: () {
              FilterConfigs configs = FilterConfigs.fromUI(
                priceIndex: _priceIndex,
                openAtDate: _openAtDateTime,
                sortingRuleIndex: _sortByIndex,
              );
              Tuple2<FilterConfigs, dynamic> result = Tuple2(configs, null);
              Navigator.pop(context, result);
            },
            child: Text(
              S.current.apply,
              style: const TextStyle(
                color: Colors.white,
                fontSize: ThemeFontSize.fontSize18,
              ),
            ),
          ),
        ],
        title: Text(
          S.current.filter_rules,
          style: const TextStyle(
            color: Colors.white,
            fontSize: ThemeFontSize.fontSize22,
          ),
        ),
        backgroundColor: ThemeColor.appPrimary,
      ),
      body: ListView(
        children: <Widget>[
          // Price level
          Padding(
            padding: const EdgeInsets.only(
              left: ThemeSize.space20,
              top: ThemeSize.space15,
            ),
            child: Text(
              S.current.filter_price,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ThemeFontSize.fontSize22,
              ),
            ),
          ),
          _createSegmentWidget(
            initValue: _priceIndex,
            segmentItems: ['\$', '\$\$', '\$\$\$', '\$\$\$\$'],
            valueChange: (i) {
              _priceIndex = i;
            },
          ),

          // Business hour
          Padding(
            padding: const EdgeInsets.only(
              left: ThemeSize.space20,
              top: ThemeSize.space15,
              right: ThemeSize.space20,
            ),
            child: Text(
              S.current.filter_business_hour,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ThemeFontSize.fontSize22,
              ),
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width.toInt() - 20,
            height: 200,
            child: CupertinoDatePicker(
              initialDateTime: _openAtDateTime,
              use24hFormat: true,
              mode: CupertinoDatePickerMode.dateAndTime,
              onDateTimeChanged: (dateTime) {
                _openAtDateTime = dateTime;
              },
            ),
          ),

          // Sorting rule
          Padding(
            padding: const EdgeInsets.only(
              left: ThemeSize.space20,
              top: ThemeSize.space15,
            ),
            child: Text(
              S.current.filter_sorting_rule,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ThemeFontSize.fontSize22,
              ),
            ),
          ),
          _createSegmentWidget(
            initValue: _sortByIndex,
            segmentItems: [
              S.current.filter_sorting_rule_best_match,
              S.current.filter_sorting_rule_distance,
              S.current.filter_sorting_rating,
              S.current.filter_sorting_review_count,
            ],
            valueChange: (i) {
              _sortByIndex = i;
            },
          ),
        ],
      ),
    );
  }

  Widget _createSegmentWidget({
    required int initValue,
    required List<String> segmentItems,
    required ValueChanged<int> valueChange,
  }) {
    Map<int, Widget> children = <int, Widget>{};

    for (int i = 0; i < segmentItems.length; i++) {
      children[i] = Text(segmentItems[i]);
    }
    return StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: const EdgeInsets.only(
          left: ThemeSize.space5,
          top: ThemeSize.space15,
        ),
        child: CupertinoSegmentedControl<int>(
          groupValue: initValue,
          children: children,
          onValueChanged: (i) {
            setState(() {
              initValue = i;
              valueChange(i);
            });
          },
        ),
      ),
    );
  }
}
