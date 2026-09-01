import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../component/component_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';
import '../../../manager/manager_barrel.dart';
import '../../main/view/view_barrel.dart';
import '../../splash/view/view_barrel.dart';
import '../bloc/bloc_barrel.dart';
import 'sign_in_actions_widget.dart';
import 'sign_in_form_widget.dart';
import 'sign_in_header_widget.dart';
import 'third_party_sign_in_widget.dart';

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
        iconTheme: const IconThemeData(color: ThemeColor.colorffffff),
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
        builder: (context, state) => Stack(
          children: <Widget>[
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    const SignInHeaderWidget(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ThemeSize.space30,
                        vertical: ThemeSize.space20,
                      ),
                      child: Column(
                        children: <Widget>[
                          SignInFormWidget(
                            formKey: _formKey,
                            onEmailSaved: (value) => _email = value,
                            onPasswordSaved: (value) => _passwd = value,
                          ),
                          SignInActionsWidget(
                            onSignIn: () => _submit(
                              () => _signInBloc.add(
                                MailSignInEvent(mail: _email, passwd: _passwd),
                              ),
                            ),
                            onSignUp: () => _submit(
                              () => _signInBloc.add(
                                MailSignUpEvent(mail: _email, passwd: _passwd),
                              ),
                            ),
                            onContinueAsGuest: _continueAsGuest,
                          ),
                          const SizedBox(height: ThemeSize.space15),
                          ThirdPartySignInWidget(
                            onGoogleSignIn: () =>
                                _signInBloc.add(GoogleSignInEvent()),
                            onAppleSignIn: () =>
                                _signInBloc.add(AppleSignInEvent()),
                          ),
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
        ),
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

  /// 驗證表單並存值，通過才執行 [onValid]。
  void _submit(VoidCallback onValid) {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      onValid();
    }
  }

  Future<void> _continueAsGuest() async {
    await SignInManager().markAsGuest();
    if (!mounted) return;
    // ignore: unawaited_futures
    _goToMainPage(context);
  }
}
