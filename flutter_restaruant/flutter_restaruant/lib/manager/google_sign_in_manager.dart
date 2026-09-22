import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data_layer/dto/dto_barrel.dart';
import '../domain/entities/entities_barrel.dart';
import '../features/utils/utils_barrel.dart';

class GoogleSignInManager {
  static final GoogleSignInManager _singleton = GoogleSignInManager._internal();

  GoogleSignInManager._internal();

  factory GoogleSignInManager() => _singleton;

  Future<Tuple2<AccountDto?, AuthFailureReason?>> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      if (googleAuth?.accessToken == null && googleAuth?.idToken == null) {
        // 未登入
        return const Tuple2<AccountDto?, AuthFailureReason?>(
          null,
          AuthFailureReason.signInFailed,
        );
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      AccountDto accountDto = AccountDto(
        type: AccountType.google,
        uid: userCredential.user?.uid ?? '',
        account: userCredential.user?.email ?? '',
      );

      return Tuple2(accountDto, null);
    } on Exception catch (e) {
      // 登入錯誤
      debugPrint('GoogleSignInManager, error = $e');
      return const Tuple2(null, AuthFailureReason.signInFailed);
    }
  }

  void signOutWithGoogle() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }
}
