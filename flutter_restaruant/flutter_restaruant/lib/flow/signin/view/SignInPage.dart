import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/LoadingWidget.dart';
import 'package:flutter_restaruant/flow/main/view/MainPage.dart';
import 'package:flutter_restaruant/flow/signin/bloc/SignInBloc.dart';
import 'package:flutter_restaruant/utils/Dimens.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SignInPage extends StatefulWidget {
  static const ROUTE_NAME = "/SignInPage";

  const SignInPage({Key? key}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  late SignInBloc _signInBloc;

  @override
  Widget build(BuildContext context) {
    this._signInBloc = BlocProvider.of<SignInBloc>(context);

    return PlatformScaffold(
        appBar: PlatformAppBar(
            title: Text('登入',
                style: TextStyle(
                    color: Colors.white, fontSize: Dimens.xxxhFontSize)),
            backgroundColor: Color(UIConstants.APP_PRIMARY_COLOR)),
        body: BlocBuilder<SignInBloc, SignInState>(builder: (context, state) {
          if (state is Success) {
            Fluttertoast.showToast(msg: "SignIn Success");
            Navigator.of(context).pushReplacementNamed(MainPage.ROUTE_NAME);
          } else if (state is Failure) {
            Fluttertoast.showToast(msg: "SignIn Fail");
          }

          return Stack(children: <Widget>[
            Align(
                alignment: Alignment.topCenter,
                child: Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Column(children: <Widget>[
                      Image.asset(
                          "images/icon_signinup_icon.gif",
                          height: 280.0,
                          width: 280.0
                      ),
                      (state is InProgress) ? const CircularProgressIndicator() : UIConstants.EMPTY_WIDGET
                    ]
                    )
                )
            ),
            Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                    padding: EdgeInsets.only(bottom: 150),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SignInButton(
                            Buttons.Google,
                            elevation: 3.0,
                            text: "使用Google繼續",
                            onPressed: () {
                              this._signInBloc.add(GoogleSignInEvent());
                              Fluttertoast.showToast(msg: "Google SignIn");
                            },
                          ),
                          SizedBox(height: 20),
                          SignInButton(Buttons.FacebookNew,
                              elevation: 3.0,
                              text: "使用Facebook繼續", onPressed: () {
                            this._signInBloc.add(FacebookSignInEvent());
                            Fluttertoast.showToast(msg: "Facebook SignIn");
                          }),
                          SizedBox(height: 20),
                          (Platform.isIOS)
                              ? SignInButton(Buttons.Apple,
                                  elevation: 3.0,
                                  text: "使用Apple繼續", onPressed: () {
                                  this._signInBloc.add(AppleSignInEvent());
                                  Fluttertoast.showToast(msg: "Apple SignIn");
                                })
                              : UIConstants.EMPTY_WIDGET
                        ])))
          ]);
        }));
  }
}
