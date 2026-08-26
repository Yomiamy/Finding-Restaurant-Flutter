import 'package:flutter/material.dart';

import '../features/foundation/style/style_barrel.dart';
import '../generated/l10n.dart';

/// 畫面查無資料或空清單時的共用佔位元件。
///
/// 支援 i18n 多語系文案、自訂圖示、輔助說明與可選的重試按鈕回呼。
class EmptyDataWidget extends StatelessWidget {
  const EmptyDataWidget({
    super.key,
    this.title,
    this.subtitle,
    this.message,
    this.icon = Icons.restaurant_outlined,
    this.onRetry,
    this.retryText,
  });

  /// 建立預設帶有多語系標題與副標題說明的空狀態元件。
  factory EmptyDataWidget.withDefaults({
    Key? key,
    String? title,
    String? subtitle,
    IconData icon = Icons.restaurant_outlined,
    VoidCallback? onRetry,
    String? retryText,
  }) {
    return EmptyDataWidget(
      key: key,
      title: title ?? S.current.empty_data_title,
      subtitle: subtitle ?? S.current.empty_data_subtitle,
      icon: icon,
      onRetry: onRetry,
      retryText: retryText,
    );
  }

  /// 主提示標題。若為 null，則於 [build] 階段取用 [S.of(context).empty_data_title]。
  final String? title;

  /// 輔助說明副標題。
  final String? subtitle;

  /// 向後相容保留欄位；若傳入此值且 [title] 為 null，則以 [message] 作為標題。
  final String? message;

  /// 佔位圖示，預設為 [Icons.restaurant_outlined]。
  final IconData icon;

  /// 重試回呼函式；若為 null 則不顯示重試按鈕。
  final VoidCallback? onRetry;

  /// 重試按鈕文字。若為 null 且 [onRetry] 存在，則於 [build] 階段取用 [S.of(context).empty_data_retry]。
  final String? retryText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final displayTitle = title ?? message ?? S.of(context).empty_data_title;
    final displayRetryText = retryText ?? S.of(context).empty_data_retry;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ThemeSize.space20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: ThemeSize.space64, color: colorScheme.outline),
            const SizedBox(height: ThemeSize.space16),
            Text(
              displayTitle,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: ThemeSize.space8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: ThemeSize.space16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(displayRetryText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
