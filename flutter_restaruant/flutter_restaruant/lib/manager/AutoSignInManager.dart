import 'dart:convert';
import 'package:flutter_restaruant/model/AccountInfo.dart';
import 'package:flutter_restaruant/utils/Constants.dart';
import 'package:flutter_restaruant/utils/Tuple.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoSignInManager {
  static final AutoSignInManager _singleton = AutoSignInManager._internal();

  AutoSignInManager._internal();

  factory AutoSignInManager() => _singleton;

  Future<Tuple2<AccountInfo?, String>> signInWithAuto() async {
    final prefs = await SharedPreferences.getInstance();
    final accountInfoJsonStr = prefs.getString(Constants.PREF_KEY_ACCOUNT_INFO);

    if (accountInfoJsonStr == null || accountInfoJsonStr.isEmpty) {
      return Tuple2(null, "");
    } else {
      AccountInfo accountInfo =
          AccountInfo.fromJson(jsonDecode(accountInfoJsonStr));
      return Tuple2(accountInfo, "");
    }
  }
}
