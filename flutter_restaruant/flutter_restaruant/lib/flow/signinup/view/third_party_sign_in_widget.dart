import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';

import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';

/// 第三方登入按鈕組。Apple 登入僅在 iOS 顯示。
class ThirdPartySignInWidget extends StatelessWidget {
  const ThirdPartySignInWidget({
    super.key,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
  });

  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SignInButton(
        Buttons.google,
        elevation: 1.0,
        text: S.current.signinup_with_google,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSize.radius12),
        ),
        onPressed: onGoogleSignIn,
      ),
      if (Platform.isIOS) ...[
        const SizedBox(height: ThemeSize.space10),
        SignInButton(
          Buttons.apple,
          elevation: 1.0,
          text: S.current.signinup_with_apple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeSize.radius12),
          ),
          onPressed: onAppleSignIn,
        ),
      ],
    ],
  );
}
