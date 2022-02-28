import 'package:flutter_restaruant/manager/SignInManager.dart';

class SettingsRepository {

  const SettingsRepository();

  Future<void> logout() async {
    // TODO: clear user id data
    SignInManager().signOut();
  }

}