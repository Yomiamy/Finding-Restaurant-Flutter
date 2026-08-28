import 'package:flutter/material.dart';

import '../../../features/foundation/style/style_barrel.dart';

/// 過濾條件頁的區塊卡片，以圖示與標題包裹單一設定控制項。
class SectionCardWidget extends StatelessWidget {
  const SectionCardWidget({
    super.key,
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
