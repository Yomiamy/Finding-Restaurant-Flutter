import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_restaruant/flow/signin/bloc/SignInBloc.dart';
import 'package:flutter_restaruant/manager/AppleSignInManager.dart';
import 'package:flutter_restaruant/manager/FacebookSignInManager.dart';
import 'package:flutter_restaruant/manager/GoogleSignInManager.dart';
import 'package:flutter_restaruant/manager/SignInManager.dart';
import 'package:flutter_restaruant/model/AccountInfo.dart';

class SignInRepository {

  static String _sUserCollectionName = "users";

  SignInManager _signInManager = SignInManager();

  Future<SignInState> signIn(SignInEvent signInEvent) async {


    if(signInEvent is GoogleSignInEvent) {
      // Google登入
      await this._signInManager.signIn(AccountType.GOOGLE);
    } else if(signInEvent is FacebookSignInEvent) {
      // Facebook登入
      await this._signInManager.signIn(AccountType.FACEBOOK);
    } else if(signInEvent is AppleSignInEvent) {
      // Apple登入
      await this._signInManager.signIn(AccountType.APPLE);
    }

    AccountInfo? accountInfo = this._signInManager.accountInfo;
    await this.updateUserInfo(accountInfo);

    return (accountInfo != null) ? Success(accountInfo: accountInfo) : Failure(event: signInEvent);
  }

  Future<void> updateUserInfo(AccountInfo? accountInfo) async {
    if(accountInfo == null) {
      return;
    }

    DocumentReference ref = FirebaseFirestore.instance.collection(_sUserCollectionName).doc(accountInfo.uid!);
    // 更新資料
    ref.set(accountInfo.toJson());
  }

}