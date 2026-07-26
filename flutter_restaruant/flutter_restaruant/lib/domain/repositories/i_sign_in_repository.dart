import '../../domain/entities/user_entity.dart';
import '../../utils/tuple.dart';

abstract class ISignInRepository {
  Future<Tuple2<UserEntity?, String>> signInUp({
    required AccountType accountType,
    bool isSignUp = false,
    String mail = '',
    String passwd = '',
  });

  Future<void> updateUserInfo(UserEntity? userEntity);
}

