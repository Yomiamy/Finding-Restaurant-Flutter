import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/features/utils/utils_barrel.dart';
import 'package:flutter_restaruant/flow/signinup/bloc/bloc_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSignInRepository extends Mock implements SignInRepository {}

void main() {
  setUpAll(() => registerFallbackValue(AccountTypeModel.none));

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
      when(
        () => mockRepo.signInUp(
          accountType: any(named: 'accountType'),
          isSignUp: any(named: 'isSignUp'),
          mail: any(named: 'mail'),
          passwd: any(named: 'passwd'),
        ),
      ).thenAnswer((_) async => const Tuple2(account, null));

      bloc.add(GoogleSignInEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const InProgress(),
          const SignInSuccess(userEntity: account),
        ]),
      );

      verify(
        () => mockRepo.signInUp(
          accountType: AccountTypeModel.google,
          isSignUp: false,
          mail: '',
          passwd: '',
        ),
      ).called(1);
    });

    test('MailSignUpEvent passes correct parameters to repository', () async {
      const account = UserEntity(type: AccountTypeModel.mail, uid: '456');
      when(
        () => mockRepo.signInUp(
          accountType: any(named: 'accountType'),
          isSignUp: any(named: 'isSignUp'),
          mail: any(named: 'mail'),
          passwd: any(named: 'passwd'),
        ),
      ).thenAnswer((_) async => const Tuple2(account, null));

      bloc.add(const MailSignUpEvent(mail: 'test@mail.com', passwd: 'secret'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const InProgress(),
          const SignUpSuccess(userEntity: account),
        ]),
      );

      verify(
        () => mockRepo.signInUp(
          accountType: AccountTypeModel.mail,
          isSignUp: true,
          mail: 'test@mail.com',
          passwd: 'secret',
        ),
      ).called(1);
    });

    test('AutoSignInEvent failure emits SignInInitial, not Failure', () async {
      when(
        () => mockRepo.signInUp(
          accountType: any(named: 'accountType'),
          isSignUp: any(named: 'isSignUp'),
          mail: any(named: 'mail'),
          passwd: any(named: 'passwd'),
        ),
      ).thenAnswer((_) async => const Tuple2(null, null));

      bloc.add(AutoSignInEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([const InProgress(), isA<SignInInitial>()]),
      );
    });

    test('SignIn failure emits Failure state', () async {
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

      bloc.add(GoogleSignInEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const InProgress(),
          const Failure(reason: AuthFailureReason.signInFailed),
        ]),
      );
    });

    test(
      'MailSignIn wrong password emits Failure with wrongPassword reason',
      () async {
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

        bloc.add(
          const MailSignInEvent(mail: 'user@example.com', passwd: 'bad'),
        );

        await expectLater(
          bloc.stream,
          emitsInOrder([
            const InProgress(),
            const Failure(reason: AuthFailureReason.wrongPassword),
          ]),
        );
      },
    );
  });
}
