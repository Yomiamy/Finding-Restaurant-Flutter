import 'package:flutter_restaruant/domain/repositories/i_sign_in_repository.dart';
import 'package:flutter_restaruant/flow/signinup/bloc/sign_in_bloc.dart';
import 'package:flutter_restaruant/domain/entities/user_entity.dart';
import 'package:flutter_restaruant/utils/tuple.dart';
import 'package:flutter_test/flutter_test.dart';

class MockSignInRepository implements ISignInRepository {
  AccountType? lastAccountType;
  bool? lastIsSignUp;
  String? lastMail;
  String? lastPasswd;
  UserEntity? returnAccountInfo;
  String returnErrorMessage = '';

  @override
  Future<Tuple2<UserEntity?, String>> signInUp({
    required AccountType accountType,
    bool isSignUp = false,
    String mail = '',
    String passwd = '',
  }) async {
    lastAccountType = accountType;
    lastIsSignUp = isSignUp;
    lastMail = mail;
    lastPasswd = passwd;
    return Tuple2(returnAccountInfo, returnErrorMessage);
  }

  @override
  Future<void> updateUserInfo(UserEntity? userEntity) async {}
}

void main() {
  group('SignInBloc Tests', () {
    late MockSignInRepository mockRepo;
    late SignInBloc bloc;

    setUp(() {
      mockRepo = MockSignInRepository();
      bloc = SignInBloc(repository: mockRepo);
    });

    tearDown(() {
      bloc.close();
    });

    test('GoogleSignInEvent passes correct parameters to repository', () async {
      final account = UserEntity(type: AccountType.google, uid: '123');
      mockRepo.returnAccountInfo = account;

      bloc.add(GoogleSignInEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const InProgress(),
          SignInSuccess(userEntity: account),
        ]),
      );

      expect(mockRepo.lastAccountType, AccountType.google);
      expect(mockRepo.lastIsSignUp, false);
    });

    test('MailSignUpEvent passes correct parameters to repository', () async {
      final account = UserEntity(type: AccountType.mail, uid: '456');
      mockRepo.returnAccountInfo = account;

      bloc.add(const MailSignUpEvent(mail: 'test@mail.com', passwd: 'secret'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const InProgress(),
          SignUpSuccess(userEntity: account),
        ]),
      );

      expect(mockRepo.lastAccountType, AccountType.mail);
      expect(mockRepo.lastIsSignUp, true);
      expect(mockRepo.lastMail, 'test@mail.com');
      expect(mockRepo.lastPasswd, 'secret');
    });

    test('SignIn failure emits Failure state', () async {
      mockRepo.returnAccountInfo = null;
      mockRepo.returnErrorMessage = 'Auth failed';

      bloc.add(GoogleSignInEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const InProgress(),
          const Failure(errorMsg: 'Auth failed'),
        ]),
      );
    });
  });
}
