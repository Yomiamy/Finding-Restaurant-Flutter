import 'package:flutter_restaruant/manager/SignInManager.dart';
import 'package:flutter_restaruant/utils/Constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {

  const SettingsRepository();

  Future<void> logout() async => SignInManager().signOut();

  Future<bool> toggleBioAuthSetting() async {
    final prefs = await SharedPreferences.getInstance();
    bool oldBiometricAuthSetting = prefs.getBool(Constants.PREF_KEY_BIOMETRIC_AUTH_SETTING) ?? false;
    bool newBiometricAuthSetting = !oldBiometricAuthSetting;

    prefs.setBool(Constants.PREF_KEY_BIOMETRIC_AUTH_SETTING, newBiometricAuthSetting);

    return newBiometricAuthSetting;
  }

}