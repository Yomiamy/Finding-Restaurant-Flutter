import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import '../data_layer/dto/dto_barrel.dart';
import '../domain/entities/entities_barrel.dart';
import '../features/utils/utils_barrel.dart';

class FacebookSignInManager {
  static final FacebookSignInManager _singleton =
      FacebookSignInManager._internal();

  FacebookSignInManager._internal();

  factory FacebookSignInManager() => _singleton;

  Future<Tuple2<AccountDto?, AuthFailureReason?>> signInWithFB() async {
    try {
      // Trigger the sign-in flow
      final LoginResult loginResult = await FacebookAuth.instance.login();

      if (loginResult.accessToken == null) {
        // 未登入
        return const Tuple2<AccountDto?, AuthFailureReason?>(
          null,
          AuthFailureReason.signInFailed,
        );
      }

      // Create a credential from the access token
      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);
      // Once signed in, return the UserCredential
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(facebookAuthCredential);
      AccountDto accountDto = AccountDto(
        type: AccountType.facebook,
        uid: userCredential.user?.uid ?? '',
        account: userCredential.user?.email ?? '',
      );

      return Tuple2(accountDto, null);
    } on FirebaseAuthException catch (e) {
      // 登入錯誤
      debugPrint('FacebookSignInManager, error = $e');
      if (e.code == 'account-exists-with-different-credential') {
        return const Tuple2(
          null,
          AuthFailureReason.accountExistsWithDifferentCredential,
        );
      } else {
        return const Tuple2(
          null,
          AuthFailureReason.signInFailed,
        );
      }
    } catch (e) {
      debugPrint('FacebookSignInManager, error = $e');
      return const Tuple2(null, AuthFailureReason.signInFailed);
    }
  }

  void signOutWithFB() async {
    await FacebookAuth.instance.logOut();
    await FirebaseAuth.instance.signOut();
  }
}
