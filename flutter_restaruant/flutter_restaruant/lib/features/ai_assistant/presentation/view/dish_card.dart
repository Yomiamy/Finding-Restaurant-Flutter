import 'package:flutter/material.dart';

import '../../domain/entities/allergen_info.dart';
import '../../domain/entities/dish_item_entity.dart';
import 'allergen_badge.dart';

/// 菜色卡片元件
class DishCard extends StatelessWidget {
  final DishItemEntity dish;

  const DishCard({
    super.key,
    required this.dish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final significantAllergens = dish.allergens
        .where((a) => a.riskLevel != AllergenRiskLevel.none)
        .toList(growable: false);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (dish.originalName.isNotEmpty &&
                          dish.originalName != dish.name) ...[
                        const SizedBox(height: 2),
                        Text(
                          dish.originalName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (dish.price > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '¥${dish.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            if (dish.spiceLevel > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '辣度：',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '🌶️' * dish.spiceLevel,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
            if (dish.ingredients.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '主要食材：${dish.ingredients.join('、')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (significantAllergens.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: significantAllergens
                    .map((a) => AllergenBadge(allergen: a))
                    .toList(growable: false),
              ),
            ],
            if (dish.dietaryTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: dish.dietaryTags.map((tag) {
                  return Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
