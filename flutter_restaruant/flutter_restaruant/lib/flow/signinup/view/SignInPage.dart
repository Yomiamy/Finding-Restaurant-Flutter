import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_restaruant/component/LoadingWidget.dart';
import 'package:flutter_restaruant/flow/main/view/MainPage.dart';
import 'package:flutter_restaruant/flow/signinup/bloc/SignInBloc.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import 'package:flutter_restaruant/utils/ViewUtils.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_restaruant/l10n/app_localizations.dart';

class SignInPage extends StatefulWidget {
  static const ROUTE_NAME = "/SignInPage";

  const SignInPage({Key? key}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = new GlobalKey<FormState>();
  late SignInBloc _signInBloc;
  String _email = "";
  String _passwd = "";

  @override
  void initState() {
    super.initState();

    this._signInBloc = BlocProvider.of<SignInBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    this._signInBloc.add(AutoSignInEvent());

    return PlatformScaffold(
        appBar: PlatformAppBar(
            title: Text(AppLocalizations.of(context)?.signin_page_title ?? "",
                style: TextStyle(
                    color: Colors.white, fontSize: UIConstants.xxxhFontSize)),
            backgroundColor: Color(UIConstants.APP_PRIMARY_COLOR)),
        body: BlocBuilder<SignInBloc, SignInState>(builder: (context, state) {
          if (state is SignInSuccess) {
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)?.signin_success_msg ?? "");

            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              // Waiting building is finish and run.
              Navigator.of(context).pushReplacementNamed(MainPage.ROUTE_NAME);
            });
          } else if (state is SignUpSuccess) {
            ViewUtils.showPromptDialog(
                context: context,
                title: AppLocalizations.of(context)
                        ?.email_signup_success_hint_title ??
                    "",
                msgWidget: PlatformText(AppLocalizations.of(context)
                        ?.email_signup_success_hint_msg ??
                    ""),
                actions: [
                  PlatformTextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: PlatformText(
                        AppLocalizations.of(context)?.confirm ?? ""),
                  )
                ]);
          } else if (state is Failure && state.errorMsg.isNotEmpty) {
            // Waiting building is finish and run.
            ViewUtils.showPromptDialog(
                context: context,
                title: AppLocalizations.of(context)?.error ?? "",
                msgWidget: PlatformText(state.errorMsg),
                actions: [
                  PlatformTextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: PlatformText(
                        AppLocalizations.of(context)?.confirm ?? ""),
                  )
                ]);
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
                            fontSize: UIConstants.xxxhFontSize,
                            color: Colors.grey)))),
            show3rdSignInUpBtns()
          ]);
        }));
  }

  Widget showLogo(SignInState state) => Column(children: <Widget>[
        Image.asset("images/icon_signinup_icon.gif",
            height: 230.0, width: 230.0),
        (state is InProgress)
            ? LoadingWidget(text: "")
            : UIConstants.EMPTY_WIDGET
      ]);

  Widget showInput(SignInState state) => Container(
      child: Form(
          key: this._formKey,
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
                    validator: (value) => (value == null || value.isEmpty)
                        ? AppLocalizations.of(context)
                                ?.email_invalid_hint_msg ??
                            ""
                        : null,
                    onSaved: (value) => this._email = value!,
                    hintText: AppLocalizations.of(context)
                            ?.email_invalid_hint_title ??
                        "",
                    cupertino: (_, __) => CupertinoTextFormFieldData(
                        // Assign a default cupertino decoration
                        decoration: PlatformTextField()
                            .createCupertinoWidget(context)
                            .decoration))))
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
                    validator: (value) => (value == null || value.isEmpty)
                        ? AppLocalizations.of(context)
                                ?.passwd_invalid_hint_msg ??
                            ""
                        : null,
                    onSaved: (value) => this._passwd = value!,
                    hintText: AppLocalizations.of(context)
                            ?.passwd_invalid_hint_title ??
                        "",
                    cupertino: (_, __) => CupertinoTextFormFieldData(
                        // Assign a default cupertino decoration
                        decoration: PlatformTextField()
                            .createCupertinoWidget(context)
                            .decoration))))
      ]));

  Widget showSignInUpBtns() => Padding(
      padding: EdgeInsets.only(top: 15),
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        PlatformElevatedButton(
            child: Text(AppLocalizations.of(context)?.signin_btn_title ?? "",
                style: TextStyle(
                    fontSize: UIConstants.xhFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            onPressed: () {
              if (this._formKey.currentState != null &&
                  this._formKey.currentState!.validate()) {
                this._formKey.currentState!.save();
                this._signInBloc.add(
                    MailSignInEvent(mail: this._email, passwd: this._passwd));
              }
            }),
        PlatformTextButton(
            child: Text(AppLocalizations.of(context)?.signup_title ?? "",
                style: TextStyle(
                    fontSize: UIConstants.mFontSize, color: Colors.grey)),
            onPressed: () {
              if (this._formKey.currentState != null &&
                  this._formKey.currentState!.validate()) {
                this._formKey.currentState!.save();
                this._signInBloc.add(
                    MailSignUpEvent(mail: this._email, passwd: this._passwd));
              }
            })
      ]));

  Widget show3rdSignInUpBtns() =>
      Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        SignInButton(
          Buttons.Google,
          elevation: 3.0,
          text: AppLocalizations.of(context)?.signinup_with_google ?? "",
          onPressed: () {
            this._signInBloc.add(GoogleSignInEvent());
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)
                        ?.signinup_with_google_hint_msg ??
                    "");
          },
        ),
        SizedBox(height: 10),
        (Platform.isIOS)
            ? SignInButton(Buttons.Apple,
                elevation: 3.0,
                text: AppLocalizations.of(context)?.signinup_with_apple ?? "",
                onPressed: () {
                this._signInBloc.add(AppleSignInEvent());
                Fluttertoast.showToast(
                    msg: AppLocalizations.of(context)
                            ?.signinup_with_apple_hint_msg ??
                        "");
              })
            : UIConstants.EMPTY_WIDGET
      ]);
}
