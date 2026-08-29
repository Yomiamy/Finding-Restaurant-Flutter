import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';
import '../../../manager/manager_barrel.dart';
import '../../signinup/view/view_barrel.dart';
import '../../splash/view/view_barrel.dart';
import '../bloc/bloc_barrel.dart';
import 'settings_account_section_widget.dart';
import 'settings_header_widget.dart';
import 'settings_info_section_widget.dart';

class SettingsPage extends StatefulWidget {
  static const routeName = '/SettingsPage';

  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsBloc _settingsBloc;

  @override
  void initState() {
    super.initState();

    _settingsBloc = BlocProvider.of<SettingsBloc>(context);
    _settingsBloc.add(const InitBioAuthSettingEvent());
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = SignInManager().isGuest;

    return Scaffold(
      appBar: AppBar(
        leading: PlatformIconButton(
          padding: const EdgeInsets.all(ThemeSize.zero),
          onPressed: () => Navigator.of(context).pop(),
          materialIcon: const Icon(Icons.arrow_back, color: ThemeColor.backBtn),
          cupertinoIcon: const Icon(
            CupertinoIcons.back,
            color: ThemeColor.backBtn,
          ),
        ),
        title: PlatformText(
          S.current.settings_title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: ThemeFontSize.fontSize22,
          ),
        ),
        backgroundColor: ThemeColor.appPrimary,
      ),
      body: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is LogoutSuccess) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              SignInPage.routeName,
              ModalRoute.withName(SplashPage.routeName),
            );
          } else if (state is AccountRemovalSuccessState) {
            // Logout after request AccountRemovalEvent
            _settingsBloc.add(const LogoutEvent());
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: ThemeSize.space16,
              vertical: ThemeSize.space25,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Center(child: SettingsHeaderWidget()),
                const SizedBox(height: ThemeSize.space30),
                const SettingsInfoSectionWidget(),
                const SizedBox(height: ThemeSize.space30),
                SettingsAccountSectionWidget(
                  onSignIn: isGuest
                      ? () => Navigator.of(
                          context,
                        ).pushNamed(SignInPage.routeName)
                      : null,
                  onLogout: () => _settingsBloc.add(const LogoutEvent()),
                  onDeleteAccount: () => _settingsBloc.add(
                    AccountRemovalEvent(
                      subject: S.current.delete_account_email_subject,
                      bodyPrefix: S.current.delete_account_email_body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
