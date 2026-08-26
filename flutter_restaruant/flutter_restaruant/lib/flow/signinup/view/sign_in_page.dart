import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../../../component/component_barrel.dart';
import '../bloc/bloc_barrel.dart';
import '../../../generated/l10n.dart';
import '../../../manager/manager_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../main/view/view_barrel.dart';
import '../../splash/view/view_barrel.dart';

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
            fontSize: ThemeFontSize.fontSize22,
          ),
        ),
        // 本頁有兩種進入方式：從 Splash 取代進來（無返回鍵），或訪客從
        // 詳情頁／設定頁 pushNamed 進來（有返回鍵）。因此不能比照其他頁面
        // 寫死 leading——那會讓 Splash 路徑也長出一顆按不動的返回鍵。
        // 交給 Flutter 依 canPop() 決定是否顯示，這裡只負責上色。
        iconTheme: const IconThemeData(color: ThemeColor.backBtn),
        backgroundColor: ThemeColor.appPrimary,
      ),
      body: BlocConsumer<SignInBloc, SignInState>(
        listener: (context, state) {
          if (state is SignInSuccess) {
            Fluttertoast.showToast(msg: S.current.signin_success_msg);
            // ignore: unawaited_futures
            _goToMainPage(context);
          } else if (state is SignUpSuccess) {
            Fluttertoast.showToast(
              msg: S.current.email_signup_success_hint_msg,
            );
            // ignore: unawaited_futures
            _goToMainPage(context);
          } else if (state is Failure) {
            Fluttertoast.showToast(msg: state.errorMsg);
          }
        },
        builder: (context, state) => _buildView(state),
      ),
    );
  }

  /// 清掉 Splash 之上的所有頁面再進主畫面。
  ///
  /// 訪客可從詳情頁最愛或設定頁進入本頁（`pushNamed`），此時登入頁並非堆疊
  /// 頂端唯一的一頁。用 `pushReplacementNamed` 只會換掉登入頁本身，把過期的
  /// 詳情頁／設定頁留在下面——那些頁面是在訪客身分下 build 的，返回鍵會回到
  /// 顯示錯誤內容的舊畫面。
  Future<void> _goToMainPage(BuildContext context) =>
      Navigator.of(context).pushNamedAndRemoveUntil(
        MainPage.routeName,
        ModalRoute.withName(SplashPage.routeName),
      );

  Widget _buildView(SignInState state) => Stack(
    children: <Widget>[
      ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: Column(
          children: <Widget>[
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
                  padding: const EdgeInsets.only(
                    left: ThemeSize.space30,
                    right: ThemeSize.space30,
                  ),
                  child: Column(
                    children: <Widget>[
                      showInput(state),
                      showSignInUpBtns(),
                      show3rdSignInUpBtns(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      (state is InProgress)
          ? const Center(child: LoadingWidget(text: ''))
          : const SizedBox.shrink(),
    ],
  );

  Widget showInput(SignInState state) => Form(
    key: _formKey,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[showEmailInput(), showPasswordInput()],
    ),
  );

  Widget showEmailInput() => Padding(
    padding: const EdgeInsets.fromLTRB(
      ThemeSize.space30,
      ThemeSize.zero,
      ThemeSize.space30,
      ThemeSize.zero,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        const Icon(Icons.mail, color: Colors.grey),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: ThemeSize.space10),
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
                    .decoration,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget showPasswordInput() => Padding(
    padding: const EdgeInsets.fromLTRB(
      ThemeSize.space30,
      ThemeSize.space15,
      ThemeSize.space30,
      ThemeSize.zero,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        const Icon(Icons.lock, color: Colors.grey),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: ThemeSize.space10),
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
                    .decoration,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget showSignInUpBtns() => Padding(
    padding: const EdgeInsets.only(top: ThemeSize.space15),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PlatformElevatedButton(
          color: const Color.fromARGB(255, 5, 97, 245),
          child: Text(
            S.current.signin_btn_title,
            style: const TextStyle(
              fontSize: ThemeFontSize.fontSize18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          onPressed: () {
            if (_formKey.currentState != null &&
                _formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              _signInBloc.add(MailSignInEvent(mail: _email, passwd: _passwd));
            }
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            PlatformTextButton(
              child: Text(
                S.current.signup_title,
                style: const TextStyle(
                  fontSize: ThemeFontSize.fontSize14,
                  color: Colors.grey,
                ),
              ),
              onPressed: () {
                if (_formKey.currentState != null &&
                    _formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _signInBloc.add(
                    MailSignUpEvent(mail: _email, passwd: _passwd),
                  );
                }
              },
            ),
            PlatformTextButton(
              child: Text(
                S.current.continue_as_guest,
                style: const TextStyle(
                  fontSize: ThemeFontSize.fontSize14,
                  color: Colors.grey,
                ),
              ),
              onPressed: () async {
                await SignInManager().markAsGuest();
                if (!mounted) return;
                // ignore: unawaited_futures
                _goToMainPage(context);
              },
            ),
          ],
        ),
      ],
    ),
  );

  Widget show3rdSignInUpBtns() => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SignInButton(
        Buttons.google,
        elevation: 3.0,
        text: S.current.signinup_with_google,
        onPressed: () => _signInBloc.add(GoogleSignInEvent()),
      ),
      const SizedBox(height: ThemeSize.space10),
      (Platform.isIOS)
          ? SignInButton(
              Buttons.apple,
              elevation: 3.0,
              text: S.current.signinup_with_apple,
              onPressed: () => _signInBloc.add(AppleSignInEvent()),
            )
          : const SizedBox.shrink(),
    ],
  );
}
