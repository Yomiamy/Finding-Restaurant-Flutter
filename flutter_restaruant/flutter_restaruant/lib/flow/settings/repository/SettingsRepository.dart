import 'package:flutter_restaruant/manager/SignInManager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {

  const SettingsRepository();

  Future<void> logout() async => SignInManager().signOut();

}