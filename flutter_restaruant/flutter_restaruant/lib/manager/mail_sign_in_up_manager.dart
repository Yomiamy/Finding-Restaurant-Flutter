import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data_layer/dto/account_dto.dart';
import '../domain/entities/user_entity.dart';
import '../features/utils/app_utils.dart';

class MailSignInUpManager {
  static final MailSignInUpManager _singleton = MailSignInUpManager._internal();

  MailSignInUpManager._internal();

  factory MailSignInUpManager() => _singleton;

  Future<Tuple2<AccountDto?, String>> signUpWithMail(
      String mail, String passwd) async {
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
          account: userCredential.user?.email ?? '');

      return Tuple2(accountDto, '');
    } on FirebaseAuthException catch (e) {
      String errorMsg =
          'Mail registration failed, please retry again\n${e.toString()}';

      // 註冊錯誤
      if (e.code == 'weak-password') {
        debugPrint('The password provided is too weak.');
        errorMsg =
            'Password security is low, please use another character combination';
      } else if (e.code == 'email-already-in-use') {
        debugPrint('The account already exists for that email.');
        errorMsg =
            'Email already registered, please use another email to register';
      }

      return Tuple2(null, errorMsg);
    } catch (e) {
      String errorMsg =
          'Mail registration failed, please retry again\n${e.toString()}';

      // 註冊錯誤
      debugPrint(e.toString());

      return Tuple2(null, errorMsg);
    }
  }

  Future<Tuple2<AccountDto?, String>> signInWithMail(
      String mail, String passwd) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: mail, password: passwd);
      User? user = FirebaseAuth.instance.currentUser;

      // 傳送驗證碼
      if (user != null && !user.emailVerified) {
        return const Tuple2(null, 'Email尚未驗證, 請使用驗證信驗證後再登入');
      }

      AccountDto accountDto = AccountDto(
          type: AccountType.mail,
          uid: userCredential.user?.uid ?? '',
          account: userCredential.user?.email ?? '');

      return Tuple2(accountDto, '');
    } on FirebaseAuthException catch (e) {
      // 登入錯誤
      String errorMsg = 'Mail登入失敗, 請再試一次\n${e.toString()}';

      if (e.code == 'user-not-found') {
        debugPrint('No user found for that email.');
        errorMsg = '帳號輸入錯誤或尚未註冊, 請再試一次';
      } else if (e.code == 'invalid-email') {
        debugPrint('invalid-email.');
        errorMsg = '無效Email, 請再輸入一次';
      } else if (e.code == 'wrong-password') {
        debugPrint('Wrong password provided for that user.');
        errorMsg = '密碼錯誤, 請再試一次';
      }

      return Tuple2(null, errorMsg);
    }
  }

  void signOutWithMail() async => await FirebaseAuth.instance.signOut();
}
