import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              SizedBox(
                height: ThemeSize.signInHeaderHeight,
                width: double.infinity,
                child: Image.asset(
                  'images/icon_signinup_icon.gif',
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ThemeSize.space30,
                  vertical: ThemeSize.space20,
                ),
                child: Column(
                  children: <Widget>[
                    showInput(state),
                    showSignInUpBtns(),
                    const SizedBox(height: ThemeSize.space15),
                    show3rdSignInUpBtns(),
                  ],
                ),
              ),
            ],
          ),
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
      children: <Widget>[
        showEmailInput(),
        const SizedBox(height: ThemeSize.space15),
        showPasswordInput(),
      ],
    ),
  );

  Widget showEmailInput() => TextFormField(
    maxLines: 1,
    autofocus: false,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    decoration: InputDecoration(
      filled: true,
      prefixIcon: const Icon(Icons.email_outlined),
      hintText: S.current.email_invalid_hint_title,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ThemeSize.radius12),
      ),
    ),
    validator: (value) => (value == null || value.isEmpty)
        ? S.current.email_invalid_hint_msg
        : null,
    onSaved: (value) => _email = value ?? '',
  );

  Widget showPasswordInput() => TextFormField(
    maxLines: 1,
    obscureText: true,
    autofocus: false,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    decoration: InputDecoration(
      filled: true,
      prefixIcon: const Icon(Icons.lock_outline),
      hintText: S.current.passwd_invalid_hint_title,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ThemeSize.radius12),
      ),
    ),
    validator: (value) => (value == null || value.isEmpty)
        ? S.current.passwd_invalid_hint_msg
        : null,
    onSaved: (value) => _passwd = value ?? '',
  );

  Widget showSignInUpBtns() => Padding(
    padding: const EdgeInsets.only(top: ThemeSize.space20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            minimumSize: const Size.fromHeight(ThemeSize.primaryButtonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ThemeSize.radius12),
            ),
          ),
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
        const SizedBox(height: ThemeSize.space10),
        // 窄螢幕（約 < 480dp）時兩顆按鈕的固有寬度會超出單行，
        // OverflowBar 會自動改為垂直排列，避免 RenderFlex overflow。
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowAlignment: OverflowBarAlignment.center,
          overflowSpacing: ThemeSize.space5,
          children: <Widget>[
            TextButton(
              child: Text(
                S.current.signup_title,
                style: TextStyle(
                  fontSize: ThemeFontSize.fontSize14,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
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
            OutlinedButton.icon(
              icon: const Icon(Icons.person_outline, size: ThemeSize.size18),
              label: Text(
                S.current.continue_as_guest,
                style: const TextStyle(fontSize: ThemeFontSize.fontSize14),
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ThemeSize.radius12),
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
        elevation: 1.0,
        text: S.current.signinup_with_google,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeSize.radius12),
        ),
        onPressed: () => _signInBloc.add(GoogleSignInEvent()),
      ),
      if (Platform.isIOS) ...[
        const SizedBox(height: ThemeSize.space10),
        SignInButton(
          Buttons.apple,
          elevation: 1.0,
          text: S.current.signinup_with_apple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeSize.radius12),
          ),
          onPressed: () => _signInBloc.add(AppleSignInEvent()),
        ),
      ],
    ],
  );
}
