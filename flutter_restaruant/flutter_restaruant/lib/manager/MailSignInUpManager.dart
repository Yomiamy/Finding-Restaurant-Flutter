
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_restaruant/model/AccountInfo.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';

class MailSignInUpManager {
  static final MailSignInUpManager _singleton = MailSignInUpManager._internal();

  MailSignInUpManager._internal();

  factory MailSignInUpManager() => _singleton;

  Future<Tuple2<AccountInfo?, String>> signUpWithMail(String mail, String passwd) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: mail,
          password: passwd
      );
      User? user = FirebaseAuth.instance.currentUser;

      // 傳送驗證碼
      if (user!= null && !user.emailVerified) {
        await user.sendEmailVerification();
      }

      AccountInfo accountInfo = AccountInfo(
          type: AccountType.MAIL,
          uid:userCredential.user?.uid ?? "",
          account: userCredential.user?.email ?? ""
      );

      return Tuple2(accountInfo, "");
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Mail註冊失敗, 請再試一次\n${e.toString()}";

      // 註冊錯誤
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
        errorMsg = "密碼安全性偏低, 請使用其他字元組合";
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
        errorMsg = "Email已被使用, 請使用其他Email註冊";
      }

      return Tuple2(null, errorMsg);
    } catch (e) {
      String errorMsg = "Mail註冊失敗, 請再試一次\n${e.toString()}";

      // 註冊錯誤
      print(e);

      return Tuple2(null, errorMsg);
    }

  }

  Future<Tuple2<AccountInfo?, String>> signInWithMail(String mail, String passwd) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: mail,
          password: passwd
      );
      User? user = FirebaseAuth.instance.currentUser;

      // 傳送驗證碼
      if (user!= null && !user.emailVerified) {
        return Tuple2(null, "Email尚未驗證, 請使用驗證信驗證後再登入");
      }

      AccountInfo accountInfo = AccountInfo(
          type: AccountType.MAIL,
          uid:userCredential.user?.uid ?? "",
          account: userCredential.user?.email ?? ""
      );

      return Tuple2(accountInfo, "");
    } on FirebaseAuthException catch (e) {
      // 登入錯誤
      String errorMsg = "Mail登入失敗, 請再試一次\n${e.toString()}";

      if (e.code == 'user-not-found') {
        print('No user found for that email.');
        errorMsg = "帳號輸入錯誤或尚未註冊, 請再試一次";
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
        errorMsg = "密碼錯誤, 請再試一次";
      }

      return Tuple2(null, errorMsg);
    }
  }
}