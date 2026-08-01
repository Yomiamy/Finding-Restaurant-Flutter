import '../../domain/entities/user_entity.dart';
import '../../features/utils/app_utils.dart';

abstract interface class SignInRepository {
  Future<Tuple2<UserEntity?, String>> signInUp({
    required AccountType accountType,
    bool isSignUp = false,
    String mail = '',
    String passwd = '',
  });

  Future<void> updateUserInfo(UserEntity? userEntity);
}
