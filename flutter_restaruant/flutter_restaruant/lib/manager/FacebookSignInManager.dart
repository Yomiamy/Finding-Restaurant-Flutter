import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_restaruant/model/AccountInfo.dart';

class FacebookSignInManager {

  static final FacebookSignInManager _singleton = FacebookSignInManager._internal();

  FacebookSignInManager._internal();

  factory FacebookSignInManager() => _singleton;

  Future<AccountInfo?> signInWithFB() async {
    try {
      // Trigger the sign-in flow
      final LoginResult loginResult = await FacebookAuth.instance.login();

      if(loginResult.accessToken == null) {
        // 未登入
        return null;
      }

      // Create a credential from the access token
      final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(loginResult.accessToken!.token);

      // Once signed in, return the UserCredential
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
      return AccountInfo(uid:userCredential.user?.uid ?? "", account: userCredential.user?.email ?? "");
    } on Exception catch(e) {
      // 登入錯誤
      print("FacebookSignInManager, error = $e");
      return null;
    }
  }

  void signInOutWithFB() async => await FacebookAuth.instance.logOut();
}