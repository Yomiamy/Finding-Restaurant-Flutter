import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/flow/settings/bloc/SettingsBloc.dart';
import 'package:flutter_restaruant/flow/signinup/view/SignInPage.dart';
import 'package:flutter_restaruant/manager/BiometricSignInManager.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import 'package:settings_ui/settings_ui.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    this._settingsBloc.add(InitBioAuthSettingEvent());
    bool isSupportBiometricAuth = BiometricSignInManager().isSupportBiometricAuth;

    return PlatformScaffold(
        appBar: PlatformAppBar(
            leading: PlatformIconButton(
                padding: EdgeInsets.all(0),
                onPressed: () => Navigator.of(context).pop(),
                materialIcon: Icon(Icons.arrow_back,
                    color: Color(UIConstants.BACK_BTN_COLOR)),
                cupertinoIcon: Icon(CupertinoIcons.back,
                    color: Color(UIConstants.BACK_BTN_COLOR))),
            title: PlatformText('設定',
                style: TextStyle(
                    color: Colors.white, fontSize: Dimens.xxxhFontSize)),
            backgroundColor: Color(UIConstants.APP_PRIMARY_COLOR)),
        body: BlocBuilder<SettingsBloc, SettingsState>(builder: (context, state) {
          bool bioAuthSettingSwitchValue = false;

          if(state is LogoutSuccess) {
            WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
              // Waiting building is finish and run.
              Navigator.of(context).pushNamedAndRemoveUntil(SignInPage.ROUTE_NAME, ModalRoute.withName('/'));
            });
          } else if (state is ToggleBioAuthSettingState) {
            bioAuthSettingSwitchValue = state.settingValue;
          } else if (state is InitBioAuthSettingState) {
            bioAuthSettingSwitchValue = state.settingValue;
          }

          return SettingsList(
            sections: [
              this.createHeadSection(),
              this.createInfoSettingsSection(bioAuthSettingSwitchValue, isSupportBiometricAuth),
              this.createLogoutSection(),
            ]
          );
        }));
  }

  AbstractSettingsSection createHeadSection() => CustomSettingsSection(
      child: Image.asset("images/icon_setting_icon.gif",
          height: 230.0,
          width: 230.0));

  AbstractSettingsSection createInfoSettingsSection(bool bioAuthSettingSwitchValue, bool isSupportBiometricAuth) =>
      SettingsSection(title: PlatformText('資訊'), tiles: <SettingsTile>[
        SettingsTile(
          leading: Icon(Icons.info),
          title: PlatformText('版本'),
          value: PlatformText('1.2.3'),
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
          padding: EdgeInsets.only(left: 20, top: 50, right: 20),
          child: SizedBox(
              height: 60,
              child: PlatformElevatedButton(
                  color: Colors.red,
                  child: Text("登出",
                      style: TextStyle(
                          fontSize: Dimens.xhFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  onPressed: () {
                    this._settingsBloc.add(LogoutEvent());
                  })
          )
      ));
}
