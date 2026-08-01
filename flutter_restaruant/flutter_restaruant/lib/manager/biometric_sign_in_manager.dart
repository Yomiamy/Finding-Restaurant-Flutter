import 'dart:convert';

import '../data_layer/dto/account_dto.dart';

import '../features/foundation/constants/app_constants.dart';
import '../features/utils/app_utils.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricSignInManager {
  static final BiometricSignInManager _singleton =
      BiometricSignInManager._internal();

  BiometricSignInManager._internal() {
    initBioSignInInfo();
  }

  factory BiometricSignInManager() => _singleton;

  final _localAuth = LocalAuthentication();
  late List<BiometricType> _availableBiometrics;
  late bool isSupportBiometricAuth;
  late bool isSupportFingerPrintAuth;
  late bool isSupportFaceIdAuth;

  Future<void> initBioSignInInfo() async {
    _availableBiometrics = await _localAuth.getAvailableBiometrics();
    isSupportBiometricAuth = _availableBiometrics.isNotEmpty;
    isSupportFingerPrintAuth =
        _availableBiometrics.contains(BiometricType.fingerprint);
    isSupportFaceIdAuth = _availableBiometrics.contains(BiometricType.face);
  }

  Future<Tuple2<AccountDto?, String>> signInWithBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    bool isBiometricSignInEnabled =
        prefs.getBool(Constants.prefKeyBiometricAuthSetting) ?? false;

    if (!isBiometricSignInEnabled) {
      // 不支援生物辨識登入
      return const Tuple2(null, '');
    }

    bool isSignInSuccess =
        await _localAuth.authenticate(localizedReason: '請使用生物識別認證進行登入');

    if (!isSignInSuccess) {
      return const Tuple2(null, '');
    } else {
      // 緩存登入資料代表登入過
      final prefs = await SharedPreferences.getInstance();
      final accountInfoJsonStr = prefs.getString(Constants.prefKeyAccountInfo);

      if (accountInfoJsonStr == null || accountInfoJsonStr.isEmpty) {
        return const Tuple2(null, '登入失敗, 請重新登入一次');
      }

      AccountDto accountDto =
          AccountDto.fromJson(jsonDecode(accountInfoJsonStr));
      return Tuple2(accountDto, '');
    }
  }

  void cancelAuthentication() => _localAuth.stopAuthentication();
}
