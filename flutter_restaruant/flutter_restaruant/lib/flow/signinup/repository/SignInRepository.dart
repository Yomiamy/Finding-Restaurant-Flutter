import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_restaruant/flow/signinup/bloc/SignInBloc.dart';
import 'package:flutter_restaruant/manager/SignInManager.dart';
import 'package:flutter_restaruant/model/AccountInfo.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/Constants.dart';

class SignInRepository {
  static const String USER_COLLECTION_NAME = "users";

  SignInManager _signInManager = SignInManager();

  Future<Tuple2<AccountInfo?, String>> signInUp(SignInEvent signInEvent) async {
    Tuple2<AccountInfo?, String> signInUpResult =
        Tuple2<AccountInfo?, String>(null, "");

    if (signInEvent is GoogleSignInEvent) {
      // Google登入
      signInUpResult = await this._signInManager.signIn(AccountType.GOOGLE);
    } else if (signInEvent is FacebookSignInEvent) {
      // Facebook登入
      signInUpResult = await this._signInManager.signIn(AccountType.FACEBOOK);
    } else if (signInEvent is AppleSignInEvent) {
      // Apple登入
      signInUpResult = await this._signInManager.signIn(AccountType.APPLE);
    } else if (signInEvent is MailSignInEvent) {
      // Mail登入
      signInUpResult = await this._signInManager.signIn(AccountType.MAIL,
          mail: signInEvent.mail, passwd: signInEvent.passwd);
    } else if (signInEvent is MailSignUpEvent) {
      // Mail註冊+登入
      signInUpResult = await this._signInManager.signUp(AccountType.MAIL,
          mail: signInEvent.mail, passwd: signInEvent.passwd);
    } else if (signInEvent is BiometricSignInEvent) {
      // 生物識別登入
      signInUpResult = await this._signInManager.signIn(AccountType.BIOMETRIC);
    } else if (signInEvent is AutoSignInEvent) {
      // 自動登入
      signInUpResult = await this._signInManager.signIn(AccountType.AUTO);
    }

    AccountInfo? accountInfo = this._signInManager.accountInfo;
    await this.updateUserInfo(accountInfo);

    return signInUpResult;
  }

  Future<void> updateUserInfo(AccountInfo? accountInfo) async {
    if (accountInfo == null) {
      return;
    }

    // 緩存登入資料代表登入過
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(Constants.PREF_KEY_ACCOUNT_INFO, jsonEncode(accountInfo));

    DocumentReference ref = FirebaseFirestore.instance
        .collection(USER_COLLECTION_NAME)
        .doc(accountInfo.uid!);
    // 更新資料
    ref.set(accountInfo.toJson());
  }
}
