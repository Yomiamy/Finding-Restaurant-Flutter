import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data_layer/dto/dto_barrel.dart';
import '../domain/entities/entities_barrel.dart';
import '../features/utils/utils_barrel.dart';

class MailSignInUpManager {
  static final MailSignInUpManager _singleton = MailSignInUpManager._internal();

  MailSignInUpManager._internal();

  factory MailSignInUpManager() => _singleton;

  Future<Tuple2<AccountDto?, AuthFailureReason?>> signUpWithMail(
    String mail,
    String passwd,
  ) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: mail, password: passwd);
      User? user = FirebaseAuth.instance.currentUser;

      // 傳送驗證碼
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }

      AccountDto accountDto = AccountDto(
        type: AccountType.mail,
        uid: userCredential.user?.uid ?? '',
        account: userCredential.user?.email ?? '',
      );

      return Tuple2(accountDto, null);
    } on FirebaseAuthException catch (e) {
      // 註冊錯誤
      if (e.code == 'weak-password') {
        debugPrint('The password provided is too weak.');
        return const Tuple2(null, AuthFailureReason.weakPassword);
      } else if (e.code == 'email-already-in-use') {
        debugPrint('The account already exists for that email.');
        return const Tuple2(null, AuthFailureReason.emailAlreadyInUse);
      }

      return const Tuple2(null, AuthFailureReason.signInFailed);
    } catch (e) {
      // 註冊錯誤
      debugPrint(e.toString());
      return const Tuple2(null, AuthFailureReason.signInFailed);
    }
  }

  Future<Tuple2<AccountDto?, AuthFailureReason?>> signInWithMail(
    String mail,
    String passwd,
  ) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: mail, password: passwd);
      User? user = FirebaseAuth.instance.currentUser;

      // 傳送驗證碼
      if (user != null && !user.emailVerified) {
        return const Tuple2(null, AuthFailureReason.emailNotVerified);
      }

      AccountDto accountDto = AccountDto(
        type: AccountType.mail,
        uid: userCredential.user?.uid ?? '',
        account: userCredential.user?.email ?? '',
      );

      return Tuple2(accountDto, null);
    } on FirebaseAuthException catch (e) {
      // 登入錯誤
      if (e.code == 'user-not-found') {
        debugPrint('No user found for that email.');
        return const Tuple2(null, AuthFailureReason.userNotFound);
      } else if (e.code == 'invalid-email') {
        debugPrint('invalid-email.');
        return const Tuple2(null, AuthFailureReason.invalidEmail);
      } else if (e.code == 'wrong-password') {
        debugPrint('Wrong password provided for that user.');
        return const Tuple2(null, AuthFailureReason.wrongPassword);
      }

      return const Tuple2(null, AuthFailureReason.signInFailed);
    } catch (e) {
      debugPrint(e.toString());
      return const Tuple2(null, AuthFailureReason.signInFailed);
    }
  }

  void signOutWithMail() async => await FirebaseAuth.instance.signOut();
}
