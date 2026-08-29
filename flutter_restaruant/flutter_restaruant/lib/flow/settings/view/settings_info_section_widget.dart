import 'package:flutter/material.dart';

import '../../../features/foundation/constants/constants_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';

/// 設定頁「資訊」區塊。
///
/// 對應 Stitch handoff spec「Settings」的 Information List：區塊標題為
/// 全大寫小字，下方接一張圓角 12dp 的群組卡片，每列固定高 52dp。
///
/// 設計稿另有 Terms of Service / Privacy Policy 兩列，因 App 目前沒有對應
/// 的頁面或連結，先不做——不放點了沒反應的假按鈕。
class SettingsInfoSectionWidget extends StatelessWidget {
  const SettingsInfoSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: ThemeSize.space16,
            bottom: ThemeSize.space8,
          ),
          child: Text(
            S.current.information_section_title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(ThemeSize.radius12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: SizedBox(
            // 設計稿（Stitch handoff）標註 Information 列 Tile H=52.0dp。
            height: ThemeSize.size52,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ThemeSize.space16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    S.current.version_tile_title,
                    style: theme.textTheme.bodyLarge,
                  ),
                  Text(
                    Constants.version,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
