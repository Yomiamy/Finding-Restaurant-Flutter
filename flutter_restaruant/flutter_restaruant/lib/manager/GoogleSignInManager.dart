import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_restaruant/model/AccountInfo.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInManager {

  static final GoogleSignInManager _singleton = GoogleSignInManager._internal();

  GoogleSignInManager._internal();

  factory GoogleSignInManager() => _singleton;

  Future<Tuple2<AccountInfo?, String>> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      if(googleAuth?.accessToken == null && googleAuth?.idToken == null) {
        // 未登入
        return Tuple2<AccountInfo?, String>(null, "發生錯誤請再試一次");
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      AccountInfo accountInfo = AccountInfo(
          type: AccountType.GOOGLE,
          uid: userCredential.user?.uid ?? "",
          account: userCredential.user?.email ?? ""
      );

      return Tuple2(accountInfo, "");
    } on Exception catch(e) {
      // 登入錯誤
       print("GoogleSignInManager, error = $e");
       return Tuple2(null, "Google登入失敗, 請再試一次\n${e.toString()}");
    }
  }

  void signOutWithGoogle() async => await GoogleSignIn().signOut();
}