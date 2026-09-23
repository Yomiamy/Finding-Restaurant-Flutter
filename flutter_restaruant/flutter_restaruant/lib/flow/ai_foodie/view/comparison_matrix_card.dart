import 'package:flutter/material.dart';

import '../../../features/foundation/foundation_barrel.dart';
import '../model/ai_foodie_model.dart';

/// GenUI 多店對比卡片橫向輪播元件
class ComparisonMatrixCard extends StatelessWidget {
  const ComparisonMatrixCard({
    super.key,
    required this.component,
    this.onRestaurantTap,
  });

  final ComparisonMatrixModel component;
  final void Function(ComparisonItemModel item)? onRestaurantTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = component.items;

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: ThemeSize.space4,
            bottom: ThemeSize.space8,
            top: ThemeSize.space8,
          ),
          child: Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: ThemeSize.size18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: ThemeSize.space8),
              Text(
                component.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: ThemeSize.space12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _ComparisonItemCard(
                item: item,
                onTap: () => onRestaurantTap?.call(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ComparisonItemCard extends StatelessWidget {
  const _ComparisonItemCard({required this.item, required this.onTap});

  final ComparisonItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 230,
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSize.radius12),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(ThemeSize.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item.rating.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: ThemeSize.space4),
                    Row(
                      children: [
                        if (item.category case final category?) ...[
                          Text(
                            category,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: ThemeSize.space8),
                        ],
                        if (item.price case final price?)
                          Text(
                            price,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: ThemeSize.space8),
                    Wrap(
                      spacing: ThemeSize.space4,
                      runSpacing: ThemeSize.space4,
                      children: item.highlights
                          .take(2)
                          .map((highlight) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withValues(
                                  alpha: 0.4,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                highlight,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ],
                ),
                if (item.address case final address?)
                  Text(
                    address,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
