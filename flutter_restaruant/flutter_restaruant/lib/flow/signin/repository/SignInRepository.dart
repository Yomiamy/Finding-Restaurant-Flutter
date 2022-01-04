import 'package:flutter_restaruant/flow/signin/bloc/SignInBloc.dart';
import 'package:flutter_restaruant/manager/AppleSignInManager.dart';
import 'package:flutter_restaruant/manager/FacebookSignInManager.dart';
import 'package:flutter_restaruant/manager/GoogleSignInManager.dart';
import 'package:flutter_restaruant/model/AccountInfo.dart';

class SignInRepository {

  Future<SignInState> signIn(SignInEvent signInEvent) async {
    if(signInEvent is GoogleSignInEvent) {
      // Google登入
      var googleSignInManager = GoogleSignInManager();

      googleSignInManager.signOutWithGoogle();

      AccountInfo? accountInfo = await googleSignInManager.signInWithGoogle();
      return (accountInfo != null) ? Success(accountInfo: accountInfo) : Failure(event: signInEvent);
    } else if(signInEvent is FacebookSignInEvent) {
      // Facebook登入
      var facebookSignInManager = FacebookSignInManager();

      facebookSignInManager.signInOutWithFB();

      AccountInfo? accountInfo = await facebookSignInManager.signInWithFB();
      return (accountInfo != null) ? Success(accountInfo: accountInfo) : Failure(event: signInEvent);
    } else if(signInEvent is AppleSignInEvent) {
      // Apple登入
      var appleSignInManager = AppleSignInManager();

      appleSignInManager.signOutWithApple();

      AccountInfo? accountInfo = await appleSignInManager.signInWithApple();
      return (accountInfo != null) ? Success(accountInfo: accountInfo) : Failure(event: signInEvent);
    } else {
      return Failure(event: signInEvent);
    }
  }

}