import 'package:flutter_restaruant/flow/signin/bloc/SignInBloc.dart';
import 'package:flutter_restaruant/manager/AppleSignInManager.dart';
import 'package:flutter_restaruant/manager/FacebookSignInManager.dart';
import 'package:flutter_restaruant/manager/GoogleSignInManager.dart';
import 'package:flutter_restaruant/manager/SignInManager.dart';
import 'package:flutter_restaruant/model/AccountInfo.dart';

class SignInRepository {

  SignInManager _signInManager = SignInManager();

  Future<SignInState> signIn(SignInEvent signInEvent) async {
    if(signInEvent is GoogleSignInEvent) {
      // Google登入
      await this._signInManager.signIn(accountType: AccountType.GOOGLE);

      AccountInfo? accountInfo = this._signInManager.accountInfo;
      return (accountInfo != null) ? Success(accountInfo: accountInfo) : Failure(event: signInEvent);
    } else if(signInEvent is FacebookSignInEvent) {
      // Facebook登入
      await this._signInManager.signIn(accountType: AccountType.FACEBOOK);

      AccountInfo? accountInfo = this._signInManager.accountInfo;
      return (accountInfo != null) ? Success(accountInfo: accountInfo) : Failure(event: signInEvent);
    } else if(signInEvent is AppleSignInEvent) {
      // Apple登入
      await this._signInManager.signIn(accountType: AccountType.APPLE);

      AccountInfo? accountInfo = this._signInManager.accountInfo;
      return (accountInfo != null) ? Success(accountInfo: accountInfo) : Failure(event: signInEvent);
    } else {
      return Failure(event: signInEvent);
    }
  }

}