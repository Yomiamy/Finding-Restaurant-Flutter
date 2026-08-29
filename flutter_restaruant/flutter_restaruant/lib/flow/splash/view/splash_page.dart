import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../di/di_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';
import '../../../manager/manager_barrel.dart';
import '../../main/view/view_barrel.dart';
import '../../signinup/view/view_barrel.dart';
import 'splash_hero_widget.dart';

class SplashPage extends StatefulWidget {
  static const routeName = '/';

  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      // Waiting building is finish and run.
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;

      // 訪客已在前次啟動選擇跳過登入，直接進主畫面。
      final String routeName = SignInManager().isGuest
          ? MainPage.routeName
          : SignInPage.routeName;

      final initialArguments = FcmManager().initialArguments;
      FcmManager().initialArguments = null; // Clear it

      if (routeName == MainPage.routeName && initialArguments != null) {
        unawaited(
          Navigator.of(
            context,
          ).pushReplacementNamed(routeName, arguments: initialArguments),
        );
      } else {
        unawaited(Navigator.of(context).pushReplacementNamed(routeName));
      }

      // 與 5 連點喚起手勢並存的第二進入點：常駐 FAB。此 context 來自
      // SplashPage 自身（已在 Navigator/Overlay 之下的路由 widget），
      // 與 main.dart builder 傳入的外層 context 不同，attach() 找得到
      // Overlay。
      if (!kDebugMode) return;
      inspector?.attach(context: context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      // 設計稿（Stitch handoff）的底色是 surfaceBright → surface 的直向漸層。
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              theme.colorScheme.surfaceBright,
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      S.current.main_page_title,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: ThemeFontSize.fontSize28,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: ThemeSize.space30),
                    const SplashHeroWidget(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: ThemeSize.space16,
                  right: ThemeSize.space16,
                  bottom: ThemeSize.space50,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // 進度條在寬螢幕上限 320dp（設計稿的 max-w-xs），窄螢幕
                    // 則由外層 padding 收邊，因此用 maxWidth 而非固定寬。
                    // 需 Center 包住——否則 Column 傳下的寬鬆約束會讓
                    // ConstrainedBox 直接取滿最大寬度，上限形同虛設。
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: ThemeSize.size320,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(ThemeSize.space4),
                          child: LinearProgressIndicator(
                            minHeight: ThemeSize.space4,
                            color: ThemeColor.appPrimary,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: ThemeSize.space16),
                    Text(
                      S.current.signin_header_subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
