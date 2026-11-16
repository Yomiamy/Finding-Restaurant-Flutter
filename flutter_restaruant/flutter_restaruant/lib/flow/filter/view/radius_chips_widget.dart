import 'package:flutter/material.dart';

import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';

/// 搜尋半徑選項 Chip 元件，涵蓋「不限」與 Yelp API 上限 40 km 內的預設級距。
class RadiusChipsWidget extends StatelessWidget {
  /// Yelp Fusion API 允許的預設半徑選項（單位：公尺，上限 40,000）。
  static const List<int> presetRadiiMeters = [
    500,
    1000,
    3000,
    5000,
    10000,
    20000,
    40000,
  ];

  const RadiusChipsWidget({
    super.key,
    required this.selectedRadius,
    required this.onRadiusSelected,
  });

  final int? selectedRadius;
  final ValueChanged<int?> onRadiusSelected;

  String _formatRadius(int meters) {
    if (meters < 1000) {
      return '$meters m';
    }
    return '${meters ~/ 1000} km';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ThemeSize.space8,
      runSpacing: ThemeSize.space8,
      children: [
        ChoiceChip(
          label: Text(S.current.filter_radius_unlimited),
          selected: selectedRadius == null,
          onSelected: (selected) {
            if (selected) {
              onRadiusSelected(null);
            }
          },
        ),
        for (final meters in presetRadiiMeters)
          ChoiceChip(
            label: Text(_formatRadius(meters)),
            selected: selectedRadius == meters,
            onSelected: (selected) {
              onRadiusSelected(selected ? meters : null);
            },
          ),
      ],
    );
  }
}
