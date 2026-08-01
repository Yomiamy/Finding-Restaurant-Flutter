import 'dart:convert';
import '../data_layer/dto/dto_barrel.dart';

import '../features/foundation/constants/constants_barrel.dart';
import '../features/utils/utils_barrel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoSignInManager {
  static final AutoSignInManager _singleton = AutoSignInManager._internal();

  AutoSignInManager._internal();

  factory AutoSignInManager() => _singleton;

  Future<Tuple2<AccountDto?, String>> signInWithAuto() async {
    final prefs = await SharedPreferences.getInstance();
    final accountInfoJsonStr = prefs.getString(Constants.prefKeyAccountInfo);

    if (accountInfoJsonStr == null || accountInfoJsonStr.isEmpty) {
      return const Tuple2(null, '');
    } else {
      AccountDto accountDto =
          AccountDto.fromJson(jsonDecode(accountInfoJsonStr));
      return Tuple2(accountDto, '');
    }
  }
}
