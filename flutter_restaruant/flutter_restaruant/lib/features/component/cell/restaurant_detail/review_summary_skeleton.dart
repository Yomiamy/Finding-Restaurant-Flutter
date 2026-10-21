import 'package:flutter/material.dart';

import '../../../foundation/style/style_barrel.dart';
import '../../skeleton.dart';

/// 評論智慧摘要卡片的載入骨架屏
class ReviewSummarySkeleton extends StatelessWidget {
  const ReviewSummarySkeleton({super.key = const Key('ReviewSummarySkeleton')});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: ThemeSize.space12,
        vertical: ThemeSize.space8,
      ),
      padding: const EdgeInsets.all(ThemeSize.space12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ThemeSize.radius12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題列骨架
          Row(
            children: [
              Skeleton(width: ThemeSize.size20, height: ThemeSize.size20),
              SizedBox(width: ThemeSize.space8),
              Skeleton(width: 120, height: ThemeSize.size18),
            ],
          ),
          SizedBox(height: ThemeSize.space10),
          // 一句話總評骨架
          Skeleton(width: double.infinity, height: ThemeSize.size14),
          SizedBox(height: ThemeSize.space4),
          Skeleton(width: 220, height: ThemeSize.size14),
          SizedBox(height: ThemeSize.space12),
          // 亮點與注意事項骨架
          Skeleton(width: 90, height: ThemeSize.size14),
          SizedBox(height: ThemeSize.space4),
          Skeleton(width: 260, height: ThemeSize.size14),
          SizedBox(height: ThemeSize.space4),
          Skeleton(width: 200, height: ThemeSize.size14),
          SizedBox(height: ThemeSize.space12),
          // 招牌標籤骨架
          Wrap(
            spacing: ThemeSize.space8,
            runSpacing: ThemeSize.space5,
            children: [
              Skeleton(width: 76, height: ThemeSize.size24),
              Skeleton(width: 88, height: ThemeSize.size24),
              Skeleton(width: 64, height: ThemeSize.size24),
            ],
          ),
        ],
      ),
    );
  }
}
