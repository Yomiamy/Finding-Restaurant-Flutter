import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../bloc/settings_bloc.dart';
import '../../signinup/view/sign_in_page.dart';
import '../../splash/view/splash_page.dart';
import '../../../manager/biometric_sign_in_manager.dart';
import '../../../manager/sign_in_manager.dart';
import '../../../features/foundation/constants/app_constants.dart';
import 'package:settings_ui/settings_ui.dart';
import '../../../generated/l10n.dart';
import '../../../gen/colors.gen.dart';
import '../../../features/foundation/style/style.dart';

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
    bool isSupportBiometricAuth =
        BiometricSignInManager().isSupportBiometricAuth;

    return Scaffold(
        appBar: AppBar(
            leading: PlatformIconButton(
                padding: const EdgeInsets.all(Sizes.zero),
                onPressed: () => Navigator.of(context).pop(),
                materialIcon:
                    const Icon(Icons.arrow_back, color: ColorName.backBtnColor),
                cupertinoIcon: const Icon(CupertinoIcons.back,
                    color: ColorName.backBtnColor)),
            title: PlatformText(S.current.settings_title,
                style: const TextStyle(
                    color: Colors.white, fontSize: UIConstants.xxxhFontSize)),
            backgroundColor: ColorName.appPrimaryColor),
        body: BlocConsumer<SettingsBloc, SettingsState>(
            listener: (context, state) {
          if (state is LogoutSuccess) {
            Navigator.of(context).pushNamedAndRemoveUntil(SignInPage.routeName,
                ModalRoute.withName(SplashPage.routeName));
          } else if (state is AccountRemovalSuccessState) {
            // Logout after request AccountRemovalEvent
            _settingsBloc.add(const LogoutEvent());
          }
        }, builder: (context, state) {
          bool bioAuthSettingSwitchValue = false;

          if (state is ToggleBioAuthSettingState) {
            bioAuthSettingSwitchValue = state.settingValue;
          } else if (state is InitBioAuthSettingState) {
            bioAuthSettingSwitchValue = state.settingValue;
          }

          return SettingsList(sections: [
            createHeadSection(),
            createInfoSettingsSection(
                bioAuthSettingSwitchValue, isSupportBiometricAuth),
            createLogoutSection(),
          ]);
        }));
  }

  AbstractSettingsSection createHeadSection() => CustomSettingsSection(
      child: Image.asset('images/icon_setting_icon.gif',
          height: 230.0, width: 230.0));

  AbstractSettingsSection createInfoSettingsSection(
          bool bioAuthSettingSwitchValue, bool isSupportBiometricAuth) =>
      SettingsSection(
          title: PlatformText(S.current.information_section_title),
          tiles: <SettingsTile>[
            SettingsTile(
              leading: const Icon(Icons.info),
              title: PlatformText(S.current.version_tile_title),
              value: PlatformText(Constants.version),
            ),
            // TODO:判斷生物辨識
            // SettingsTile.switchTile(
            //     leading: Icon(Icons.fingerprint),
            //     title: PlatformText('生物辨識'),
            //     initialValue: bioAuthSettingSwitchValue,
            //     onToggle: (value) {
            //       this._settingsBloc.add(ToggleBioAuthSettingEvent());
            //     })
          ]);

  AbstractSettingsSection createLogoutSection() {
    // 訪客沒有帳號可登出或刪除，改提供轉為正式帳號的入口。
    final Widget child = SignInManager().isGuest
        ? SizedBox(
            height: 50,
            child: PlatformElevatedButton(
                color: ColorName.appPrimaryColor,
                child: Text(S.current.signin_or_signup_title,
                    style: const TextStyle(
                        fontSize: UIConstants.xhFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                onPressed: () =>
                    Navigator.of(context).pushNamed(SignInPage.routeName)),
          )
        : Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              height: 50,
              child: PlatformElevatedButton(
                  color: Colors.red,
                  child: Text(S.current.logout_section_title,
                      style: const TextStyle(
                          fontSize: UIConstants.xhFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  onPressed: () {
                    _settingsBloc.add(const LogoutEvent());
                  }),
            ),
            const SizedBox(height: Sizes.space20),
            GestureDetector(
              onTap: () {
                _settingsBloc.add(AccountRemovalEvent(
                    subject: S.current.delete_account_email_subject,
                    bodyPrefix: S.current.delete_account_email_body));
              },
              child: Text(S.current.delete_account_title,
                  style: const TextStyle(
                      fontSize: UIConstants.hFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.red)),
            )
          ]);

    return CustomSettingsSection(
        child: Padding(
            padding: const EdgeInsets.only(
                left: Sizes.space25, top: Sizes.space50, right: Sizes.space25),
            child: child));
  }
}
