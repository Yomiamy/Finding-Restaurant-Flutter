import 'dart:async';
import '../../domain/repositories/settings_repository.dart';
import '../../manager/sign_in_manager.dart';
import '../../utils/constants.dart';
import '../../utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepo implements SettingsRepository {
  const SettingsRepo();

  @override
  Future<void> logout() async {
    // 清除緩存的設定
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
    // ignore: unawaited_futures
    SignInManager().signOut();
  }

  @override
  Future<bool> initBioAuthSetting() async {
    final prefs = await SharedPreferences.getInstance();
    bool oldBiometricAuthSetting =
        prefs.getBool(Constants.prefKeyBiometricAuthSetting) ?? false;

    return oldBiometricAuthSetting;
  }

  @override
  Future<bool> toggleBioAuthSetting() async {
    final prefs = await SharedPreferences.getInstance();
    bool oldBiometricAuthSetting =
        prefs.getBool(Constants.prefKeyBiometricAuthSetting) ?? false;
    bool newBiometricAuthSetting = !oldBiometricAuthSetting;

    // ignore: unawaited_futures
    prefs.setBool(
        Constants.prefKeyBiometricAuthSetting, newBiometricAuthSetting);

    return newBiometricAuthSetting;
  }

  @override
  Future<bool> removeAccount(String subject, String bodyPrefix) async {
    String account = SignInManager().accountDto?.account ?? '';

    if (account.isEmpty) {
      return false;
    }

    Utils.openUrl(
        rawUrl:
            'mailto:o1984531@gmail.com?subject=$subject&body=${bodyPrefix + account}');
    return true;
  }
}
