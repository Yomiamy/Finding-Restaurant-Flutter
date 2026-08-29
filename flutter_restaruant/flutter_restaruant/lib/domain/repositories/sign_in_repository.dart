import '../../features/utils/utils_barrel.dart';
import '../entities/entities_barrel.dart';

abstract interface class SignInRepository {
  Future<Tuple2<UserEntity?, String>> signInUp({
    required AccountType accountType,
    bool isSignUp = false,
    String mail = '',
    String passwd = '',
  });

  Future<void> updateUserInfo(UserEntity? userEntity);
}
