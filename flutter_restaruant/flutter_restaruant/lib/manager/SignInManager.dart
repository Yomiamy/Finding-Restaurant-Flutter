import 'package:flutter_restaruant/manager/AppleSignInManager.dart';
import 'package:flutter_restaruant/manager/FacebookSignInManager.dart';
import 'package:flutter_restaruant/manager/GoogleSignInManager.dart';
import 'package:flutter_restaruant/model/AccountInfo.dart';

class SignInManager {

  static final SignInManager _singleton = SignInManager._internal();

  SignInManager._internal();

  factory SignInManager() => _singleton;

  AccountInfo? accountInfo;
  GoogleSignInManager _googleSignInManager = GoogleSignInManager();
  AppleSignInManager _appleSignInManager = AppleSignInManager();
  FacebookSignInManager _facebookSignInManager = FacebookSignInManager();

  Future<void> signIn({accountType:AccountType}) async {
    switch(accountType) {
      case AccountType.GOOGLE:
        this.accountInfo = await this._googleSignInManager.signInWithGoogle();
        break;
      case AccountType.APPLE:
        this.accountInfo = await this._appleSignInManager.signInWithApple();
        break;
      case AccountType.FACEBOOK:
        this.accountInfo = await this._facebookSignInManager.signInWithFB();
        break;
    }
  }

  Future<void> signOut() async {
    switch(this.accountInfo?.type) {
      case AccountType.GOOGLE:
        this._googleSignInManager.signOutWithGoogle();
        break;
      case AccountType.APPLE:
        this._appleSignInManager.signOutWithApple();
        break;
      case AccountType.FACEBOOK:
        this._facebookSignInManager.signOutWithFB();
        break;
    }
    this.accountInfo = null;
  }
}