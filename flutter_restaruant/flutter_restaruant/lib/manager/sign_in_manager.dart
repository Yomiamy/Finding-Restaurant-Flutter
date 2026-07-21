import 'package:flutter_restaruant/manager/apple_sign_in_manager.dart';
import 'package:flutter_restaruant/manager/auto_sign_in_manager.dart';
import 'package:flutter_restaruant/manager/biometric_sign_in_manager.dart';
import 'package:flutter_restaruant/manager/facebook_sign_in_manager.dart';
import 'package:flutter_restaruant/manager/google_sign_in_manager.dart';
import 'package:flutter_restaruant/model/account_info.dart';
import 'package:flutter_restaruant/utils/tuple.dart';

import 'mail_sign_in_up_manager.dart';

class SignInManager {
  static final SignInManager _singleton = SignInManager._internal();

  SignInManager._internal();

  factory SignInManager() => _singleton;

  AccountInfo? accountInfo;
  GoogleSignInManager _googleSignInManager = GoogleSignInManager();
  AppleSignInManager _appleSignInManager = AppleSignInManager();
  FacebookSignInManager _facebookSignInManager = FacebookSignInManager();
  MailSignInUpManager _mailSignInUpManager = MailSignInUpManager();
  BiometricSignInManager _biometricAuthManager = BiometricSignInManager();
  AutoSignInManager _autoSignInManager = AutoSignInManager();

  Future<Tuple2<AccountInfo?, String>> signIn(AccountType accountType,
      {String mail = "", String passwd = ""}) async {
    Tuple2<AccountInfo?, String> signInResult = Tuple2(null, "");

    switch (accountType) {
      case AccountType.GOOGLE:
        signInResult = await this._googleSignInManager.signInWithGoogle();
        break;
      case AccountType.APPLE:
        signInResult = await this._appleSignInManager.signInWithApple();
        break;
      case AccountType.FACEBOOK:
        signInResult = await this._facebookSignInManager.signInWithFB();
        break;
      case AccountType.BIOMETRIC:
        signInResult = await this._biometricAuthManager.signInWithBiometric();
        break;
      case AccountType.AUTO:
        signInResult = await this._autoSignInManager.signInWithAuto();
        break;
      case AccountType.MAIL:
      default:
        signInResult =
            await this._mailSignInUpManager.signInWithMail(mail, passwd);
        break;
    }
    this.accountInfo = signInResult.item1;

    return signInResult;
  }

  Future<Tuple2<AccountInfo?, String>> signUp(AccountType accountType,
      {required String mail, required String passwd}) async {
    Tuple2<AccountInfo?, String> signUpResult = Tuple2(null, "");

    switch (accountType) {
      case AccountType.MAIL:
      default:
        signUpResult =
            await this._mailSignInUpManager.signUpWithMail(mail, passwd);
        break;
    }
    this.accountInfo = signUpResult.item1;

    return signUpResult;
  }

  Future<void> signOut() async {
    switch (this.accountInfo?.type) {
      case AccountType.GOOGLE:
        this._googleSignInManager.signOutWithGoogle();
        break;
      case AccountType.APPLE:
        this._appleSignInManager.signOutWithApple();
        break;
      case AccountType.FACEBOOK:
        this._facebookSignInManager.signOutWithFB();
        break;
      case AccountType.MAIL:
      default:
        this._mailSignInUpManager.signOutWithMail();
        break;
    }

    this.accountInfo = null;
  }
}
