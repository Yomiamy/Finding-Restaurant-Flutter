import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../../../component/loading_widget.dart';
import '../bloc/sign_in_bloc.dart';
import '../../../generated/l10n.dart';
import '../../../utils/ui_constants.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../gen/colors.gen.dart';
import '../../main/view/main_page.dart';

class SignInPage extends StatefulWidget {
  static const routeName = '/SignInPage';

  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  late SignInBloc _signInBloc;
  String _email = '';
  String _passwd = '';

  @override
  void initState() {
    super.initState();

    _signInBloc = BlocProvider.of<SignInBloc>(context);
    _signInBloc.add(AutoSignInEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.current.signin_page_title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: UIConstants.xxxhFontSize,
          ),
        ),
        backgroundColor: ColorName.appPrimaryColor,
      ),
      body: BlocConsumer<SignInBloc, SignInState>(
        listener: (context, state) {
          if (state is SignInSuccess) {
            Fluttertoast.showToast(msg: S.current.signin_success_msg);
            // ignore: unawaited_futures
            Navigator.of(context).pushReplacementNamed(MainPage.routeName);
          } else if (state is SignUpSuccess) {
            Fluttertoast.showToast(msg: S.current.signin_success_msg);
            // ignore: unawaited_futures
            Navigator.of(context).pushReplacementNamed(MainPage.routeName);
          } else if (state is Failure) {
            Fluttertoast.showToast(msg: state.errorMsg);
          }
        },
        builder: (context, state) => _buildView(state),
      ),
    );
  }

  Widget _buildView(SignInState state) => Stack(children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: Column(children: <Widget>[
            Expanded(
              flex: 1,
              child: Image.asset(
                'images/icon_signinup_icon.gif',
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.only(left: 30, right: 30),
                      child: Column(children: <Widget>[
                        showInput(state),
                        showSignInUpBtns(),
                        show3rdSignInUpBtns(),
                      ])),
                ))
          ]),
        ),
        (state is InProgress)
            ? const LoadingWidget(text: '')
            : UIConstants.emptyWidget
      ]);

  Widget showInput(SignInState state) => Form(
      key: _formKey,
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[showEmailInput(), showPasswordInput()]));

  Widget showEmailInput() => Padding(
      padding: const EdgeInsets.fromLTRB(30.0, 0.0, 30.0, 0.0),
      child: Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
        const Icon(
          Icons.mail,
          color: Colors.grey,
        ),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: PlatformTextFormField(
                    maxLines: 1,
                    autofocus: false,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) => (value == null || value.isEmpty)
                        ? S.current.email_invalid_hint_msg
                        : null,
                    onSaved: (value) => _email = value!,
                    hintText: S.current.email_invalid_hint_title,
                    cupertino: (_, __) => CupertinoTextFormFieldData(
                        // Assign a default cupertino decoration
                        decoration: const PlatformTextField()
                            .createCupertinoWidget(context)
                            .decoration))))
      ]));

  Widget showPasswordInput() => Padding(
      padding: const EdgeInsets.fromLTRB(30.0, 15.0, 30.0, 0.0),
      child: Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
        const Icon(
          Icons.lock,
          color: Colors.grey,
        ),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: PlatformTextFormField(
                    maxLines: 1,
                    obscureText: true,
                    autofocus: false,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) => (value == null || value.isEmpty)
                        ? S.current.passwd_invalid_hint_msg
                        : null,
                    onSaved: (value) => _passwd = value!,
                    hintText: S.current.passwd_invalid_hint_title,
                    cupertino: (_, __) => CupertinoTextFormFieldData(
                        // Assign a default cupertino decoration
                        decoration: const PlatformTextField()
                            .createCupertinoWidget(context)
                            .decoration))))
      ]));

  Widget showSignInUpBtns() => Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        PlatformElevatedButton(
            color: const Color.fromARGB(255, 5, 97, 245),
            child: Text(S.current.signin_btn_title,
                style: const TextStyle(
                    fontSize: UIConstants.xhFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            onPressed: () {
              if (_formKey.currentState != null &&
                  _formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                _signInBloc.add(
                    MailSignInEvent(mail: _email, passwd: _passwd));
              }
            }),
        PlatformTextButton(
            child: Text(S.current.signup_title,
                style: const TextStyle(
                    fontSize: UIConstants.mFontSize, color: Colors.grey)),
            onPressed: () {
              if (_formKey.currentState != null &&
                  _formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                _signInBloc.add(
                    MailSignUpEvent(mail: _email, passwd: _passwd));
              }
            })
      ]));

  Widget show3rdSignInUpBtns() =>
      Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        SignInButton(
          Buttons.google,
          elevation: 3.0,
          text: S.current.signinup_with_google,
          onPressed: () {
            _signInBloc.add(GoogleSignInEvent());
            Fluttertoast.showToast(
                msg: S.current.signinup_with_google_hint_msg);
          },
        ),
        const SizedBox(height: 10),
        (Platform.isIOS)
            ? SignInButton(Buttons.apple,
                elevation: 3.0,
                text: S.current.signinup_with_apple, onPressed: () {
                _signInBloc.add(AppleSignInEvent());
                Fluttertoast.showToast(
                    msg: S.current.signinup_with_apple_hint_msg);
              })
            : UIConstants.emptyWidget
      ]);
}

