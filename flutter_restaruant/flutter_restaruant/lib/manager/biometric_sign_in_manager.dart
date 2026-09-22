import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data_layer/dto/dto_barrel.dart';
import '../domain/entities/entities_barrel.dart';
import '../features/foundation/constants/constants_barrel.dart';
import '../features/utils/utils_barrel.dart';
import '../generated/l10n.dart';

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
    isSupportFingerPrintAuth = _availableBiometrics.contains(
      BiometricType.fingerprint,
    );
    isSupportFaceIdAuth = _availableBiometrics.contains(BiometricType.face);
  }

  Future<Tuple2<AccountDto?, AuthFailureReason?>> signInWithBiometric({
    String? localizedReason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    bool isBiometricSignInEnabled =
        prefs.getBool(Constants.prefKeyBiometricAuthSetting) ?? false;

    if (!isBiometricSignInEnabled) {
      // 不支援生物辨識登入
      return const Tuple2(null, null);
    }

    final reason = localizedReason ?? _resolveDefaultReason();

    bool isSignInSuccess = await _localAuth.authenticate(
      localizedReason: reason,
    );

    if (!isSignInSuccess) {
      return const Tuple2(null, AuthFailureReason.biometricFailed);
    } else {
      // 緩存登入資料代表登入過
      final prefs = await SharedPreferences.getInstance();
      final accountInfoJsonStr = prefs.getString(Constants.prefKeyAccountInfo);

      if (accountInfoJsonStr == null || accountInfoJsonStr.isEmpty) {
        return const Tuple2(null, AuthFailureReason.biometricFailed);
      }

      AccountDto accountDto = AccountDto.fromJson(
        jsonDecode(accountInfoJsonStr),
      );
      return Tuple2(accountDto, null);
    }
  }

  String _resolveDefaultReason() {
    try {
      return S.current.biometric_prompt_reason;
    } catch (_) {
      final isZh = Intl.getCurrentLocale().startsWith('zh');
      return isZh ? '請使用生物識別認證進行登入' : 'Please authenticate to sign in';
    }
  }

  void cancelAuthentication() => _localAuth.stopAuthentication();
}
