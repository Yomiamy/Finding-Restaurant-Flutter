import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/features/utils/utils_barrel.dart';
import 'package:flutter_restaruant/flow/signinup/bloc/bloc_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignInRepository extends Mock implements SignInRepository {}

void main() {
  setUpAll(() => registerFallbackValue(AccountTypeModel.none));

  group('SignInBloc Tests', () {
    late _MockSignInRepository mockRepo;

    setUp(() {
      mockRepo = _MockSignInRepository();
    });

    blocTest<SignInBloc, SignInState>(
      'GoogleSignInEvent passes correct parameters to repository',
      build: () {
        const account = UserEntity(type: AccountTypeModel.google, uid: '123');
        when(
          () => mockRepo.signInUp(
            accountType: any(named: 'accountType'),
            isSignUp: any(named: 'isSignUp'),
            mail: any(named: 'mail'),
            passwd: any(named: 'passwd'),
          ),
        ).thenAnswer((_) async => const Tuple2(account, null));
        return SignInBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(GoogleSignInEvent()),
      expect: () => [
        const InProgress(),
        const SignInSuccess(
          userEntity: UserEntity(type: AccountTypeModel.google, uid: '123'),
        ),
      ],
      verify: (_) {
        verify(
          () => mockRepo.signInUp(
            accountType: AccountTypeModel.google,
            isSignUp: false,
            mail: '',
            passwd: '',
          ),
        ).called(1);
      },
    );

    blocTest<SignInBloc, SignInState>(
      'MailSignUpEvent passes correct parameters to repository',
      build: () {
        const account = UserEntity(type: AccountTypeModel.mail, uid: '456');
        when(
          () => mockRepo.signInUp(
            accountType: any(named: 'accountType'),
            isSignUp: any(named: 'isSignUp'),
            mail: any(named: 'mail'),
            passwd: any(named: 'passwd'),
          ),
        ).thenAnswer((_) async => const Tuple2(account, null));
        return SignInBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(
        const MailSignUpEvent(mail: 'test@mail.com', passwd: 'secret'),
      ),
      expect: () => [
        const InProgress(),
        const SignUpSuccess(
          userEntity: UserEntity(type: AccountTypeModel.mail, uid: '456'),
        ),
      ],
      verify: (_) {
        verify(
          () => mockRepo.signInUp(
            accountType: AccountTypeModel.mail,
            isSignUp: true,
            mail: 'test@mail.com',
            passwd: 'secret',
          ),
        ).called(1);
      },
    );

    blocTest<SignInBloc, SignInState>(
      'AutoSignInEvent failure emits SignInInitial, not Failure',
      build: () {
        when(
          () => mockRepo.signInUp(
            accountType: any(named: 'accountType'),
            isSignUp: any(named: 'isSignUp'),
            mail: any(named: 'mail'),
            passwd: any(named: 'passwd'),
          ),
        ).thenAnswer((_) async => const Tuple2(null, null));
        return SignInBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(AutoSignInEvent()),
      expect: () => [const InProgress(), isA<SignInInitial>()],
    );

    blocTest<SignInBloc, SignInState>(
      'SignIn failure emits Failure state',
      build: () {
        when(
          () => mockRepo.signInUp(
            accountType: any(named: 'accountType'),
            isSignUp: any(named: 'isSignUp'),
            mail: any(named: 'mail'),
            passwd: any(named: 'passwd'),
          ),
        ).thenAnswer(
          (_) async => const Tuple2(null, AuthFailureReason.signInFailed),
        );
        return SignInBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(GoogleSignInEvent()),
      expect: () => [
        const InProgress(),
        const Failure(reason: AuthFailureReason.signInFailed),
      ],
    );

    blocTest<SignInBloc, SignInState>(
      'MailSignIn wrong password emits Failure with wrongPassword reason',
      build: () {
        when(
          () => mockRepo.signInUp(
            accountType: any(named: 'accountType'),
            isSignUp: any(named: 'isSignUp'),
            mail: any(named: 'mail'),
            passwd: any(named: 'passwd'),
          ),
        ).thenAnswer(
          (_) async => const Tuple2(null, AuthFailureReason.wrongPassword),
        );
        return SignInBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(
        const MailSignInEvent(mail: 'user@example.com', passwd: 'bad'),
      ),
      expect: () => [
        const InProgress(),
        const Failure(reason: AuthFailureReason.wrongPassword),
      ],
    );
  });
}
