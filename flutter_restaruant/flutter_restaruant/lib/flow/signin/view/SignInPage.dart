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
  late String _email;
  late String _passwd;
  bool _isLoginForm = true;

  @override
  Widget build(BuildContext context) {
    this._signInBloc = BlocProvider.of<SignInBloc>(context);
    return PlatformScaffold(
        appBar: PlatformAppBar(
            title: Text('登入/註冊',
                style: TextStyle(
                    color: Colors.white, fontSize: Dimens.xxxhFontSize)),
            backgroundColor: Color(UIConstants.APP_PRIMARY_COLOR)),
        body: BlocBuilder<SignInBloc, SignInState>(builder: (context, state) {
          if (state is Success) {
            Fluttertoast.showToast(msg: "登入成功");

            WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
              // Waiting building is finish and run.
              Navigator.of(context).pushReplacementNamed(MainPage.ROUTE_NAME);
            });
          } else if (state is Failure) {
            Fluttertoast.showToast(msg: "登入失敗, 請確認帳號密碼");
          }

          return ListView(children: <Widget>[
            showLogo(state),
            showInput(state),
            showSignInUpBtns(),
            Padding(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                child: Center(
                    child: Text("---------OR---------",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: Dimens.xxxhFontSize,
                            color: Colors.grey)))),
            show3rdSignInUpBtns()
          ]);
        }));
  }

  Widget showLogo(SignInState state) => Column(children: <Widget>[
    Image.asset("images/icon_signinup_icon.gif",
        height: 230.0, width: 230.0),
    (state is InProgress)
        ? const CircularProgressIndicator()
        : UIConstants.EMPTY_WIDGET
  ]);

  Widget showInput(SignInState state) => Container(
      child: Form(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[showEmailInput(), showPasswordInput()])));

  Widget showEmailInput() => Padding(
      padding: const EdgeInsets.fromLTRB(30.0, 0.0, 30.0, 0.0),
      child: Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
        Icon(
          Icons.mail,
          color: Colors.grey,
        ),
        Expanded(
            child: Padding(
                padding: EdgeInsets.only(left: 10),
                child: PlatformTextFormField(
                  maxLines: 1,
                  autofocus: false,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? "請輸入正確Email" : null,
                  onSaved: (value) => this._email = value!,
                  hintText: 'Email帳號',
                  cupertino: (_, __) => CupertinoTextFormFieldData(
                    // Assign a default cupertino decoration
                    decoration: PlatformTextField().createCupertinoWidget(context).decoration
                  )
                )))
      ]));

  Widget showPasswordInput() => Padding(
      padding: const EdgeInsets.fromLTRB(30.0, 15.0, 30.0, 0.0),
      child: Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
        Icon(
          Icons.lock,
          color: Colors.grey,
        ),
        Expanded(
            child: Padding(
                padding: EdgeInsets.only(left: 10),
                child: PlatformTextFormField(
                    maxLines: 1,
                    obscureText: true,
                    autofocus: false,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) =>
                    (value == null || value.isEmpty) ? "請輸入密碼" : null,
                    onSaved: (value) => this._passwd = value!,
                    hintText: "密碼",
                    cupertino: (_, __) => CupertinoTextFormFieldData(
                      // Assign a default cupertino decoration
                        decoration: PlatformTextField().createCupertinoWidget(context).decoration
                    )
                )))
      ]));

  Widget showSignInUpBtns() => Padding(
      padding: EdgeInsets.only(top: 15),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PlatformElevatedButton(
                child: Text(this._isLoginForm ? '登入' : '註冊',
                    style: TextStyle(
                        fontSize: Dimens.xhFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                onPressed: () {
                  Fluttertoast.showToast(msg: "Login");
                }),
            PlatformTextButton(
                child: Text(
                    this._isLoginForm ? '註冊新帳號' : '已經有帳號了? 點此登入',
                    style: TextStyle(
                        fontSize: Dimens.mFontSize,
                        color: Colors.grey)),
                onPressed: () {})
          ]));

  Widget show3rdSignInUpBtns() => Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
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
    SignInButton(Buttons.FacebookNew, elevation: 3.0, text: "使用Facebook繼續",
        onPressed: () {
          this._signInBloc.add(FacebookSignInEvent());
          Fluttertoast.showToast(msg: "Facebook SignIn");
        }),
    SizedBox(height: 20),
    (Platform.isIOS)
        ? SignInButton(Buttons.Apple, elevation: 3.0, text: "使用Apple繼續",
        onPressed: () {
          this._signInBloc.add(AppleSignInEvent());
          Fluttertoast.showToast(msg: "Apple SignIn");
        })
        : UIConstants.EMPTY_WIDGET
  ]);
}
