import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../model/model_barrel.dart';
import '../../../features/utils/utils_barrel.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: ThemeColor.backBtn),
        ),
        title: Text(
          S.current.filter_rules,
          style: const TextStyle(
            color: Colors.white,
            fontSize: ThemeFontSize.fontSize22,
          ),
        ),
        backgroundColor: ThemeColor.appPrimary,
      ),
      body: Column(
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeSize.space16,
          vertical: ThemeSize.space12,
        ),
        children: <Widget>[
          _SectionCard(
            icon: Icons.attach_money,
            title: S.current.filter_price,
            child: _SegmentControl(
              initValue: _priceIndex,
              segmentItems: const ['\$', '\$\$', '\$\$\$', '\$\$\$\$'],
              valueChange: (i) {
                _priceIndex = i;
              },
            ),
          ),
          const SizedBox(height: ThemeSize.space16),
          _SectionCard(
            icon: Icons.access_time,
            title: S.current.filter_business_hour,
            child: Container(
              height: ThemeSize.datePickerHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ThemeSize.radius8),
              ),
              child: CupertinoDatePicker(
                initialDateTime: _openAtDateTime,
                use24hFormat: true,
                mode: CupertinoDatePickerMode.dateAndTime,
                onDateTimeChanged: (dateTime) {
                  _openAtDateTime = dateTime;
                },
              ),
            ),
          ),
          const SizedBox(height: ThemeSize.space16),
          _SectionCard(
            icon: Icons.sort,
            title: S.current.filter_sorting_rule,
            child: _SegmentControl(
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
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeSize.space16,
            vertical: ThemeSize.space12,
          ),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(ThemeSize.primaryButtonHeight),
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ThemeSize.radius12),
              ),
            ),
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
                fontSize: ThemeFontSize.fontSize18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeSize.radius12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ThemeSize.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: ThemeSize.size20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: ThemeSize.space8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ThemeSize.space12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SegmentControl extends StatefulWidget {
  const _SegmentControl({
    required this.initValue,
    required this.segmentItems,
    required this.valueChange,
  });

  final int initValue;
  final List<String> segmentItems;
  final ValueChanged<int> valueChange;

  @override
  State<_SegmentControl> createState() => _SegmentControlState();
}

class _SegmentControlState extends State<_SegmentControl> {
  late int _selectedIndex = widget.initValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <int, Widget>{
      for (int i = 0; i < widget.segmentItems.length; i++)
        i: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeSize.space8,
            vertical: ThemeSize.space4,
          ),
          child: Text(widget.segmentItems[i]),
        ),
    };

    return SizedBox(
      width: double.infinity,
      child: CupertinoSegmentedControl<int>(
        selectedColor: theme.colorScheme.primary,
        borderColor: theme.colorScheme.primary,
        groupValue: _selectedIndex,
        children: children,
        onValueChanged: (i) {
          setState(() => _selectedIndex = i);
          widget.valueChange(i);
        },
      ),
    );
  }
}
