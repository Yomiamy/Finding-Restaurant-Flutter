import 'package:flutter/material.dart';

import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';

/// 登入頁的主要與次要操作按鈕：登入、註冊、訪客模式。
///
/// 只負責呈現與轉發點擊，表單驗證與事件派發都留在頁面。
class SignInActionsWidget extends StatelessWidget {
  const SignInActionsWidget({
    super.key,
    required this.onSignIn,
    required this.onSignUp,
    required this.onContinueAsGuest,
  });

  final VoidCallback onSignIn;
  final VoidCallback onSignUp;
  final VoidCallback onContinueAsGuest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: ThemeSize.space20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              minimumSize: const Size.fromHeight(ThemeSize.size48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ThemeSize.radius12),
              ),
            ),
            onPressed: onSignIn,
            child: Text(
              S.current.signin_btn_title,
              style: const TextStyle(
                fontSize: ThemeFontSize.fontSize18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: ThemeSize.space10),
          // 窄螢幕（約 < 480dp）時兩顆按鈕的固有寬度會超出單行，
          // OverflowBar 會自動改為垂直排列，避免 RenderFlex overflow。
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowAlignment: OverflowBarAlignment.center,
            overflowSpacing: ThemeSize.space5,
            children: <Widget>[
              TextButton(
                onPressed: onSignUp,
                child: Text(
                  S.current.signup_title,
                  style: TextStyle(
                    fontSize: ThemeFontSize.fontSize14,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.person_outline, size: ThemeSize.size18),
                label: Text(
                  S.current.continue_as_guest,
                  style: const TextStyle(fontSize: ThemeFontSize.fontSize14),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ThemeSize.radius12),
                  ),
                ),
                onPressed: onContinueAsGuest,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
