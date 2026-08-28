import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../features/foundation/style/style_barrel.dart';

/// 過濾條件頁的分段選擇控制項，自行維護選中項並回報變更。
class SegmentControlWidget extends StatefulWidget {
  const SegmentControlWidget({
    super.key,
    required this.initValue,
    required this.segmentItems,
    required this.valueChange,
  });

  final int initValue;
  final List<String> segmentItems;
  final ValueChanged<int> valueChange;

  @override
  State<SegmentControlWidget> createState() => _SegmentControlWidgetState();
}

class _SegmentControlWidgetState extends State<SegmentControlWidget> {
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
