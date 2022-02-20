
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_restaruant/model/AccountInfo.dart';

class MailSignInUpManager {
  static final MailSignInUpManager _singleton = MailSignInUpManager._internal();

  MailSignInUpManager._internal();

  factory MailSignInUpManager() => _singleton;

  Future<AccountInfo?> signUpWithMail(String mail, String passwd) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: mail,
          password: passwd
      );

      return AccountInfo(
      // 傳送驗證碼
      if (user!= null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
          type: AccountType.MAIL,
          uid:userCredential.user?.uid ?? "",
          account: userCredential.user?.email ?? ""
      );
    } on FirebaseAuthException catch (e) {
      // 註冊錯誤
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      // 註冊錯誤
      print(e);
    }
    return null;
  }

  Future<AccountInfo?> signInWithMail(String mail, String passwd) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: mail,
          password: passwd
      );

      return AccountInfo(
      // 傳送驗證碼
      if (user!= null && !user.emailVerified) {
        return Tuple2(null, "Email尚未驗證, 請使用驗證信驗證後再登入");
      }
          type: AccountType.MAIL,
          uid:userCredential.user?.uid ?? "",
          account: userCredential.user?.email ?? ""
      );
    } on FirebaseAuthException catch (e) {
      // 登入錯誤
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    }
    return null;
  }
}