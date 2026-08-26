import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/features/utils/utils_barrel.dart';
import 'package:flutter_restaruant/flow/signinup/bloc/bloc_barrel.dart';
import 'package:flutter_restaruant/flow/signinup/view/sign_in_page.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSignInRepository implements SignInRepository {
  @override
  Future<Tuple2<UserEntity?, String>> signInUp({
    required AccountType accountType,
    bool isSignUp = false,
    String mail = '',
    String passwd = '',
  }) async {
    return const Tuple2(null, '');
  }

  @override
  Future<void> updateUserInfo(UserEntity? userEntity) async {}
}

void main() {
  group('SignInPage Widget Tests', () {
    late _FakeSignInRepository fakeRepo;
    late SignInBloc bloc;

    setUp(() {
      fakeRepo = _FakeSignInRepository();
      bloc = SignInBloc(repository: fakeRepo);
    });

    tearDown(() {
      bloc.close();
    });

    testWidgets('渲染輸入框、Primary FilledButton、註冊與訪客按鈕', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeData.materialLight,
          localizationsDelegates: const [S.delegate],
          home: BlocProvider<SignInBloc>.value(
            value: bloc,
            child: const SignInPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('SignIn'), findsOneWidget);
      expect(find.text('SignUp'), findsOneWidget);
      expect(find.text('Continue As Guest'), findsOneWidget);

      final filledBtn = tester.widget<FilledButton>(find.byType(FilledButton));
      final btnStyle = filledBtn.style;
      expect(
        btnStyle?.backgroundColor?.resolve({}),
        AppThemeData.materialLight.colorScheme.primary,
      );
    });

    testWidgets('空輸入送出時觸發表單驗證錯誤訊息', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeData.materialLight,
          localizationsDelegates: const [S.delegate],
          home: BlocProvider<SignInBloc>.value(
            value: bloc,
            child: const SignInPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Please input email'), findsOneWidget);
      expect(find.text('Please input password'), findsOneWidget);
    });
  });
}
