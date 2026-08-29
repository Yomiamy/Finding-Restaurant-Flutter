import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/entities_barrel.dart';
import '../../domain/repositories/repositories_barrel.dart';
import '../../features/foundation/constants/constants_barrel.dart';
import '../../features/utils/utils_barrel.dart';
import '../../manager/manager_barrel.dart';
import '../dto/dto_barrel.dart';

class SignInRepo implements SignInRepository {
  static const String userCollectionName = 'users';

  final SignInManager _signInManager = SignInManager();

  @override
  Future<Tuple2<UserEntity?, String>> signInUp({
    required AccountType accountType,
    bool isSignUp = false,
    String mail = '',
    String passwd = '',
  }) async {
    Tuple2<AccountDto?, String> signInUpResult =
        const Tuple2<AccountDto?, String>(null, '');

    if (isSignUp) {
      signInUpResult = await _signInManager.signUp(
        accountType,
        mail: mail,
        passwd: passwd,
      );
    } else {
      signInUpResult = await _signInManager.signIn(
        accountType,
        mail: mail,
        passwd: passwd,
      );
    }

    AccountDto? accountDto = _signInManager.accountDto;
    UserEntity? userEntity = accountDto != null
        ? UserEntity.fromDto(accountDto)
        : null;
    await updateUserInfo(userEntity);

    return Tuple2<UserEntity?, String>(userEntity, signInUpResult.item2);
  }

  @override
  Future<void> updateUserInfo(UserEntity? userEntity) async {
    if (userEntity == null) {
      return;
    }

    AccountDto dto = userEntity.toDto;

    // 緩存登入資料代表登入過
    final prefs = await SharedPreferences.getInstance();
    // ignore: unawaited_futures
    prefs.setString(Constants.prefKeyAccountInfo, jsonEncode(dto.toJson()));

    DocumentReference ref = FirebaseFirestore.instance
        .collection(userCollectionName)
        .doc(dto.uid!);
    // ignore: unawaited_futures
    ref.set(dto.toJson());
  }
}
