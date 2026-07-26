import 'apple_sign_in_manager.dart';
import 'auto_sign_in_manager.dart';
import 'biometric_sign_in_manager.dart';
import 'facebook_sign_in_manager.dart';
import 'google_sign_in_manager.dart';
import '../data_layer/dto/account_dto.dart';
import '../domain/entities/user_entity.dart';
import '../utils/tuple.dart';

import 'mail_sign_in_up_manager.dart';

class SignInManager {
  static final SignInManager _singleton = SignInManager._internal();

  SignInManager._internal();

  factory SignInManager() => _singleton;

  AccountDto? accountDto;
  final GoogleSignInManager _googleSignInManager = GoogleSignInManager();
  final AppleSignInManager _appleSignInManager = AppleSignInManager();
  final FacebookSignInManager _facebookSignInManager = FacebookSignInManager();
  final MailSignInUpManager _mailSignInUpManager = MailSignInUpManager();
  final BiometricSignInManager _biometricAuthManager = BiometricSignInManager();
  final AutoSignInManager _autoSignInManager = AutoSignInManager();

  Future<Tuple2<AccountDto?, String>> signIn(AccountType accountType,
      {String mail = '', String passwd = ''}) async {
    Tuple2<AccountDto?, String> signInResult = const Tuple2(null, '');

    switch (accountType) {
      case AccountType.google:
        signInResult = await _googleSignInManager.signInWithGoogle();
        break;
      case AccountType.apple:
        signInResult = await _appleSignInManager.signInWithApple();
        break;
      case AccountType.facebook:
        signInResult = await _facebookSignInManager.signInWithFB();
        break;
      case AccountType.biometric:
        signInResult = await _biometricAuthManager.signInWithBiometric();
        break;
      case AccountType.auto:
        signInResult = await _autoSignInManager.signInWithAuto();
        break;
      case AccountType.mail:
      default:
        signInResult =
            await _mailSignInUpManager.signInWithMail(mail, passwd);
        break;
    }
    accountDto = signInResult.item1;

    return signInResult;
  }

  Future<Tuple2<AccountDto?, String>> signUp(AccountType accountType,
      {required String mail, required String passwd}) async {
    Tuple2<AccountDto?, String> signUpResult = const Tuple2(null, '');

    switch (accountType) {
      case AccountType.mail:
      default:
        signUpResult =
            await _mailSignInUpManager.signUpWithMail(mail, passwd);
        break;
    }
    accountDto = signUpResult.item1;

    return signUpResult;
  }

  Future<void> signOut() async {
    switch (accountDto?.type) {
      case AccountType.google:
        _googleSignInManager.signOutWithGoogle();
        break;
      case AccountType.apple:
        _appleSignInManager.signOutWithApple();
        break;
      case AccountType.facebook:
        _facebookSignInManager.signOutWithFB();
        break;
      case AccountType.mail:
      default:
        _mailSignInUpManager.signOutWithMail();
        break;
    }

    accountDto = null;
  }
}
