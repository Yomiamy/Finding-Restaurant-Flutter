import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_restaruant/model/AccountInfo.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';

class FacebookSignInManager {

  static final FacebookSignInManager _singleton = FacebookSignInManager._internal();

  FacebookSignInManager._internal();

  factory FacebookSignInManager() => _singleton;

  Future<Tuple2<AccountInfo?, String>> signInWithFB() async {
    try {
      // Trigger the sign-in flow
      final LoginResult loginResult = await FacebookAuth.instance.login();

      if(loginResult.accessToken == null) {
        // 未登入
        return Tuple2<AccountInfo?, String>(null, "發生錯誤請再試一次");
      }

      // Create a credential from the access token
      final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(loginResult.accessToken!.token);

      // Once signed in, return the UserCredential
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
      AccountInfo accountInfo = AccountInfo(
          type: AccountType.FACEBOOK,
          uid:userCredential.user?.uid ?? "",
          account: userCredential.user?.email ?? ""
      );

      return Tuple2(accountInfo, "");
    } on Exception catch(e) {
      // 登入錯誤
      print("FacebookSignInManager, error = $e");
      return Tuple2(null, "FB登入失敗, 請再試一次\n${e.toString()}");
    }
  }

  void signOutWithFB() async => await FacebookAuth.instance.logOut();
}