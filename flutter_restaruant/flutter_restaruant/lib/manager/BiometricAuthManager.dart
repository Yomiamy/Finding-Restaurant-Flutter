
import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/widgets.dart';
import 'package:flutter_restaruant/model/AccountInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthManager {

  static final BiometricAuthManager _singleton = BiometricAuthManager._internal();

  BiometricAuthManager._internal();

  factory BiometricAuthManager() => _singleton;

  var _localAuth = LocalAuthentication();
  Future<List<BiometricType>> get _availableBiometrics async => await _localAuth.getAvailableBiometrics();
  Future<bool> get isBiometricAvailable async => (await _availableBiometrics).isNotEmpty;
  Future<bool> get isSupportFingerPrintAuth async {
    List<BiometricType> availableBiometrics = await _availableBiometrics;
    return availableBiometrics.contains(BiometricType.fingerprint);
  }
  Future<bool> get isSupportFaceIdAuth async {
    List<BiometricType> availableBiometrics = await _availableBiometrics;
    return availableBiometrics.contains(BiometricType.face);
  }

  Future<Tuple2<AccountInfo?, String>> signInWithBiometric() async {
    bool isAuthSuccess = await _localAuth.authenticate(localizedReason: '請使用生物識別認證進行登入');

    if(!isAuthSuccess) {
      return Tuple2(null, "登入失敗, 請再試一次");
    } else {
      // 緩存登入資料代表登入過
      final prefs = await SharedPreferences.getInstance();
      final accountInfoJsonStr = prefs.getString(Constants.PREF_KEY_ACCOUNT_INFO);

      if (accountInfoJsonStr == null || accountInfoJsonStr.isEmpty) {
        return Tuple2(null, "登入失敗, 請重新登入一次");
      }

      AccountInfo accountInfo = AccountInfo.fromJson(jsonDecode(accountInfoJsonStr));
      return Tuple2(accountInfo, "");
    }
  }

  void cancelAuthentication() => _localAuth.stopAuthentication();
}