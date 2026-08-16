import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data_layer/dto/dto_barrel.dart';
import '../domain/entities/entities_barrel.dart';
import '../features/utils/utils_barrel.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInManager {
  static final GoogleSignInManager _singleton = GoogleSignInManager._internal();

  GoogleSignInManager._internal();

  factory GoogleSignInManager() => _singleton;

  Future<Tuple2<AccountDto?, String>> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      if (googleAuth?.accessToken == null && googleAuth?.idToken == null) {
        // 未登入
        return const Tuple2<AccountDto?, String>(
          null,
          'Error occurred, please retry again',
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

      return Tuple2(accountDto, '');
    } on Exception catch (e) {
      // 登入錯誤
      debugPrint('GoogleSignInManager, error = $e');
      return Tuple2(
        null,
        'Google sign in fail, please retry again\n${e.toString()}',
      );
    }
  }

  void signOutWithGoogle() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }
}
