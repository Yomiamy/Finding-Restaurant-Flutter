import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/flow/settings/bloc/settings_bloc.dart';
import 'package:flutter_restaruant/flow/signinup/view/sign_in_page.dart';
import 'package:flutter_restaruant/flow/splash/view/splash_page.dart';
import 'package:flutter_restaruant/manager/biometric_sign_in_manager.dart';
import 'package:flutter_restaruant/utils/constants.dart';
import 'package:flutter_restaruant/utils/ui_constants.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_restaruant/gen/colors.gen.dart';

class SettingsPage extends StatefulWidget {
  static const ROUTE_NAME = "/SettingsPage";

  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsBloc _settingsBloc;

  @override
  void initState() {
    super.initState();

    this._settingsBloc = BlocProvider.of<SettingsBloc>(context);
    this._settingsBloc.add(InitBioAuthSettingEvent());
  }

  @override
  Widget build(BuildContext context) {
    bool isSupportBiometricAuth =
        BiometricSignInManager().isSupportBiometricAuth;

    return Scaffold(
        appBar: AppBar(
            leading: PlatformIconButton(
                padding: EdgeInsets.all(0),
                onPressed: () => Navigator.of(context).pop(),
                materialIcon: Icon(Icons.arrow_back,
                    color: ColorName.backBtnColor),
                cupertinoIcon: Icon(CupertinoIcons.back,
                    color: ColorName.backBtnColor)),
            title: PlatformText(
                S.current.settings_title,
                style: TextStyle(
                    color: Colors.white, fontSize: UIConstants.xxxhFontSize)),
            backgroundColor: ColorName.appPrimaryColor),
        body:
            BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is LogoutSuccess) {
            Navigator.of(context).pushNamedAndRemoveUntil(
                SignInPage.ROUTE_NAME,
                ModalRoute.withName(SplashPage.ROUTE_NAME));
          } else if (state is AccountRemovalSuccessState) {
            // Logout after request AccountRemovalEvent
            this._settingsBloc.add(LogoutEvent());
          }
        },
        builder: (context, state) {
          bool bioAuthSettingSwitchValue = false;

          if (state is ToggleBioAuthSettingState) {
            bioAuthSettingSwitchValue = state.settingValue;
          } else if (state is InitBioAuthSettingState) {
            bioAuthSettingSwitchValue = state.settingValue;
          }

          return SettingsList(sections: [
            this.createHeadSection(),
            this.createInfoSettingsSection(
                bioAuthSettingSwitchValue, isSupportBiometricAuth),
            this.createLogoutSection(),
          ]);
        }));
  }

  AbstractSettingsSection createHeadSection() => CustomSettingsSection(
      child: Image.asset("images/icon_setting_icon.gif",
          height: 230.0, width: 230.0));

  AbstractSettingsSection createInfoSettingsSection(
          bool bioAuthSettingSwitchValue, bool isSupportBiometricAuth) =>
      SettingsSection(
          title: PlatformText(
              S.current.information_section_title),
          tiles: <SettingsTile>[
            SettingsTile(
              leading: Icon(Icons.info),
              title: PlatformText(
                  S.current.version_tile_title),
              value: PlatformText(Constants.VERSION),
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

  AbstractSettingsSection createLogoutSection() => CustomSettingsSection(
      child: Padding(
          padding: EdgeInsets.only(left: 25, top: 50, right: 25),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              height: 50,
              child: PlatformElevatedButton(
                  color: Colors.red,
                  child: Text(
                      S.current.logout_section_title,
                      style: TextStyle(
                          fontSize: UIConstants.xhFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  onPressed: () {
                    this._settingsBloc.add(LogoutEvent());
                  }),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                this._settingsBloc.add(AccountRemovalEvent(
                    subject: S.current.delete_account_email_subject,
                    bodyPrefix: S.current.delete_account_email_body));
              },
              child: Text(
                  S.current.delete_account_title,
                  style: TextStyle(
                      fontSize: UIConstants.hFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.red)),
            )
          ])));
}
