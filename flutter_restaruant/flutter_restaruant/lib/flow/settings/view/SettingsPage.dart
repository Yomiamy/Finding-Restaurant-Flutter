import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/flow/settings/bloc/SettingsBloc.dart';
import 'package:flutter_restaruant/flow/signin/bloc/SignInBloc.dart';
import 'package:flutter_restaruant/flow/signin/view/SignInPage.dart';
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
  @override
  Widget build(BuildContext context) {
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
          return SettingsList(
            sections: [
              SettingsSection(
                title: PlatformText('Common'),
                tiles: <SettingsTile>[
                  SettingsTile(
                    leading: Icon(Icons.info),
                    title: PlatformText('版本'),
                    value: PlatformText('1.2.3'),
                  ),
                  SettingsTile.switchTile(
                    onToggle: (value) {},
                    initialValue: true,
                    leading: Icon(Icons.format_paint),
                    title: Text('Enable custom theme'),
                  ),
                ],
              ),
              CustomSettingsSection(
                  child: Column(children: <Widget>[
                PlatformElevatedButton(
                    color: Colors.red,
                    child: Text("登出",
                        style: TextStyle(
                            fontSize: Dimens.xhFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(SignInPage.ROUTE_NAME, ModalRoute.withName('/'));
                    })
              ]))
            ],
          );
        }));
  }
}