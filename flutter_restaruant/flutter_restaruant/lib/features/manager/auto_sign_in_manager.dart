import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data_layer/models/model_barrel.dart';
import '../../domain/entities/entities_barrel.dart';
import '../../app/constants/constants_barrel.dart';
import '../utils/utils_barrel.dart';

class AutoSignInManager {
  static final AutoSignInManager _singleton = AutoSignInManager._internal();

  AutoSignInManager._internal();

  factory AutoSignInManager() => _singleton;

  Future<Tuple2<AccountModel?, AuthFailureReason?>> signInWithAuto() async {
    final prefs = await SharedPreferences.getInstance();
    final accountInfoJsonStr = prefs.getString(Constants.prefKeyAccountInfo);

    if (accountInfoJsonStr == null || accountInfoJsonStr.isEmpty) {
      return const Tuple2(null, null);
    } else {
      AccountModel accountDto = AccountModel.fromJson(
        jsonDecode(accountInfoJsonStr),
      );
      return Tuple2(accountDto, null);
    }
  }
}
