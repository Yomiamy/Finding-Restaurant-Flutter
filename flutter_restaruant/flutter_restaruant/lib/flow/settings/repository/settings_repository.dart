import 'package:flutter_restaruant/manager/sign_in_manager.dart';
import 'package:flutter_restaruant/utils/constants.dart';
import 'package:flutter_restaruant/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  const SettingsRepository();

  Future<void> logout() async {
    // 清除緩存的設定
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
    SignInManager().signOut();
  }

  Future<bool> initBioAuthSetting() async {
    final prefs = await SharedPreferences.getInstance();
    bool oldBiometricAuthSetting =
        prefs.getBool(Constants.PREF_KEY_BIOMETRIC_AUTH_SETTING) ?? false;

    return oldBiometricAuthSetting;
  }

  Future<bool> toggleBioAuthSetting() async {
    final prefs = await SharedPreferences.getInstance();
    bool oldBiometricAuthSetting =
        prefs.getBool(Constants.PREF_KEY_BIOMETRIC_AUTH_SETTING) ?? false;
    bool newBiometricAuthSetting = !oldBiometricAuthSetting;

    prefs.setBool(
        Constants.PREF_KEY_BIOMETRIC_AUTH_SETTING, newBiometricAuthSetting);

    return newBiometricAuthSetting;
  }

  Future<bool> removeAccount(String subject, String bodyPrefix) async {
    String account = SignInManager().accountInfo?.account ?? "";

    if (account.isEmpty) {
      return false;
    }

    Utils.openUrl(
        rawUrl:
            "mailto:o1984531@gmail.com?subject=${subject}&body=${bodyPrefix + account}");
    return true;
  }
}
