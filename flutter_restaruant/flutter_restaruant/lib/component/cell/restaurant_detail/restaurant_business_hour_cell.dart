import 'package:flutter/material.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';

class RestaurantBusinessHourCell extends StatelessWidget {
  final List<RestaurantBusinessTimeEntity> _businessTimeInfos;

  const RestaurantBusinessHourCell({
    super.key = const Key('RestaurantBusinessCell'),
    required List<RestaurantBusinessTimeEntity> businessTimeInfos,
  }) : _businessTimeInfos = businessTimeInfos;

  @override
  Widget build(BuildContext context) {
    if (_businessTimeInfos.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final nowWeekDay = DateTime.now().weekday;

    final businessTimeWidgetMap = <int, List<Widget>>{};
    for (final info in _businessTimeInfos) {
      final int yelpWeekDay = info.day ?? 0;
      final String dayStr = info.dayStr;
      final String start = info.start ?? '';
      final String end = info.end ?? '';
      final bool isToday = (nowWeekDay - 1) == yelpWeekDay;

      final textStyle = isToday
          ? TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: ThemeFontSize.fontSize14,
            )
          : TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: ThemeFontSize.fontSize14,
            );

      final row = Padding(
        padding: const EdgeInsets.symmetric(vertical: ThemeSize.space4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              businessTimeWidgetMap.containsKey(yelpWeekDay) ? '' : dayStr,
              style: textStyle,
            ),
            Text('$start - $end', style: textStyle),
          ],
        ),
      );

      businessTimeWidgetMap.putIfAbsent(yelpWeekDay, () => []).add(row);
    }

    final rows = businessTimeWidgetMap.values.expand((list) => list).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeSize.space12,
        vertical: ThemeSize.space8,
      ),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSize.radius12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ThemeSize.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: [
                  Icon(
                    Icons.access_time_filled,
                    size: ThemeSize.size18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: ThemeSize.space8),
                  Text(
                    S.current.business_hour,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ThemeSize.space8),
              const Divider(height: 1),
              const SizedBox(height: ThemeSize.space8),
              ...rows,
            ],
          ),
        ),
      ),
    );
  }
}
