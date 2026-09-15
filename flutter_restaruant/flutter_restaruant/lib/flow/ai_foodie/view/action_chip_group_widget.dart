import 'package:flutter/material.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../features/foundation/foundation_barrel.dart';

/// GenUI 行動按鈕群組渲染元件
class ActionChipGroupWidget extends StatelessWidget {
  const ActionChipGroupWidget({
    super.key,
    required this.component,
    required this.onChipTap,
  });

  final ActionChipGroupComponent component;
  final void Function(ActionChipItem chip) onChipTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chips = component.chips;

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ThemeSize.space8),
      child: Wrap(
        spacing: ThemeSize.space8,
        runSpacing: ThemeSize.space8,
        children: chips.map((chip) {
          final isRoulette = chip.action == 'open_roulette';

          return ActionChip(
            avatar: isRoulette
                ? const Icon(Icons.casino_outlined, size: 16)
                : null,
            label: Text(chip.label),
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: isRoulette ? FontWeight.bold : FontWeight.normal,
              color: isRoulette
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            backgroundColor: isRoulette
                ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            side: BorderSide(
              color: isRoulette
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ThemeSize.radiusTag),
            ),
            onPressed: () => onChipTap(chip),
          );
        }).toList(growable: false),
      ),
    );
  }
}
