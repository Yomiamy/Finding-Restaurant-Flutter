import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';

import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';

/// 第三方登入按鈕組。Apple 登入在 iOS 與 macOS 顯示（兩者皆支援 Sign in with Apple）。
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
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) ...[
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
