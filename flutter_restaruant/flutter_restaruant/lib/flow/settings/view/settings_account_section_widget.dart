import 'package:flutter/material.dart';

import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';

/// 設定頁「帳戶」區塊。
///
/// 對應 Stitch handoff spec「Settings」的 Account Section：主要動作為
/// 高 48dp、圓角 12dp 的實心按鈕，下方接一顆 error 色的文字按鈕。
///
/// 設計稿只畫了已登入狀態。訪客沒有帳號可登出或刪除，改以同樣的實心按鈕
/// 提供轉為正式帳號的入口——由 [onSignIn] 是否為 null 決定走哪一種。
class SettingsAccountSectionWidget extends StatelessWidget {
  const SettingsAccountSectionWidget({
    super.key,
    this.onSignIn,
    this.onLogout,
    this.onDeleteAccount,
  });

  /// 訪客用：前往登入／註冊。非 null 時代表目前為訪客。
  final VoidCallback? onSignIn;

  final VoidCallback? onLogout;
  final VoidCallback? onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isGuest = onSignIn != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: ThemeSize.space16,
            bottom: ThemeSize.space8,
          ),
          child: Text(
            S.current.account_section_title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        if (isGuest)
          _FilledAction(
            label: S.current.signin_or_signup_title,
            onPressed: onSignIn,
          )
        else ...<Widget>[
          _FilledAction(
            icon: Icons.logout,
            label: S.current.logout_section_title,
            onPressed: onLogout,
          ),
          const SizedBox(height: ThemeSize.space16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onDeleteAccount,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                padding: const EdgeInsets.symmetric(
                  vertical: ThemeSize.space12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ThemeSize.radius12),
                ),
              ),
              child: Text(
                S.current.delete_account_title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 帳戶區塊的主要動作按鈕：滿版、高 48dp、圓角 12dp 的實心樣式。
class _FilledAction extends StatelessWidget {
  const _FilledAction({required this.label, this.icon, this.onPressed});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = FilledButton.styleFrom(
      backgroundColor: ThemeColor.appPrimary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(ThemeSize.size48),
      textStyle: const TextStyle(
        fontSize: ThemeFontSize.fontSize18,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeSize.radius12),
      ),
    );

    if (icon == null) {
      return FilledButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
