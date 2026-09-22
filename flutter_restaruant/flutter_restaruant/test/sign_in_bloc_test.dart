import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/flow/signinup/bloc/bloc_barrel.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/features/utils/utils_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

class MockSignInRepository implements SignInRepository {
  AccountTypeModel? lastAccountType;
  bool? lastIsSignUp;
  String? lastMail;
  String? lastPasswd;
  UserEntity? returnAccountInfo;
  AuthFailureReason? returnFailureReason;

  @override
  Future<Tuple2<UserEntity?, AuthFailureReason?>> signInUp({
    required AccountTypeModel accountType,
    bool isSignUp = false,
    String mail = '',
    String passwd = '',
  }) async {
    lastAccountType = accountType;
    lastIsSignUp = isSignUp;
    lastMail = mail;
    lastPasswd = passwd;
    return Tuple2(returnAccountInfo, returnFailureReason);
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
      const account = UserEntity(type: AccountTypeModel.google, uid: '123');
      mockRepo.returnAccountInfo = account;

      bloc.add(GoogleSignInEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const InProgress(),
          const SignInSuccess(userEntity: account),
        ]),
      );

      expect(mockRepo.lastAccountType, AccountTypeModel.google);
      expect(mockRepo.lastIsSignUp, false);
    });

    test('MailSignUpEvent passes correct parameters to repository', () async {
      const account = UserEntity(type: AccountTypeModel.mail, uid: '456');
      mockRepo.returnAccountInfo = account;

      bloc.add(const MailSignUpEvent(mail: 'test@mail.com', passwd: 'secret'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const InProgress(),
          const SignUpSuccess(userEntity: account),
        ]),
      );

      expect(mockRepo.lastAccountType, AccountTypeModel.mail);
      expect(mockRepo.lastIsSignUp, true);
      expect(mockRepo.lastMail, 'test@mail.com');
      expect(mockRepo.lastPasswd, 'secret');
    });

    test('AutoSignInEvent failure emits SignInInitial, not Failure', () async {
      mockRepo.returnAccountInfo = null;
      mockRepo.returnFailureReason = null;

      bloc.add(AutoSignInEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([const InProgress(), isA<SignInInitial>()]),
      );
    });

    test('SignIn failure emits Failure state', () async {
      mockRepo.returnAccountInfo = null;
      mockRepo.returnFailureReason = AuthFailureReason.signInFailed;

      bloc.add(GoogleSignInEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const InProgress(),
          const Failure(reason: AuthFailureReason.signInFailed),
        ]),
      );
    });

    test('MailSignIn wrong password emits Failure with wrongPassword reason', () async {
      mockRepo.returnAccountInfo = null;
      mockRepo.returnFailureReason = AuthFailureReason.wrongPassword;

      bloc.add(const MailSignInEvent(mail: 'user@example.com', passwd: 'bad'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const InProgress(),
          const Failure(reason: AuthFailureReason.wrongPassword),
        ]),
      );
    });
  });
}
