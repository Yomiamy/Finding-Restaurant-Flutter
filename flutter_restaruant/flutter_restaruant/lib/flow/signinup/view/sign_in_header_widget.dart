import 'package:flutter/material.dart';

import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';

/// 登入頁頁首品牌區塊。
///
/// 對應 Stitch handoff spec「Sign In」的 Image Section：底圖鋪滿、由下往上
/// 的黑色漸層，標題與副標貼齊左下。漸層是為了讓白字在任何底圖上都可讀，
/// 不是純裝飾——換底圖時不要拿掉。
class SignInHeaderWidget extends StatelessWidget {
  const SignInHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: ThemeSize.signInHeaderHeight,
    width: MediaQuery.sizeOf(context).width,
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset('images/img_signin_header.jpg', fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: <Color>[Colors.black54, Colors.transparent],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(ThemeSize.space20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  S.current.main_page_title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: ThemeFontSize.fontSize28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: ThemeSize.space5),
                Text(
                  S.current.signin_header_subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: ThemeFontSize.fontSize16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
