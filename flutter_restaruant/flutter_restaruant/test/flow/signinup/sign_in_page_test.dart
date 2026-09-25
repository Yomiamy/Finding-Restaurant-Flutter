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
import 'package:mocktail/mocktail.dart';

class _MockSignInRepository extends Mock implements SignInRepository {}

void main() {
  setUpAll(() => registerFallbackValue(AccountTypeModel.none));

  group('SignInPage Widget Tests', () {
    late _MockSignInRepository fakeRepo;
    late SignInBloc bloc;

    setUp(() {
      fakeRepo = _MockSignInRepository();
      when(
        () => fakeRepo.signInUp(
          accountType: any(named: 'accountType'),
          isSignUp: any(named: 'isSignUp'),
          mail: any(named: 'mail'),
          passwd: any(named: 'passwd'),
        ),
      ).thenAnswer((_) async => const Tuple2(null, null));
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

    testWidgets('窄螢幕（320 / 400 寬）次要按鈕不發生 RenderFlex overflow', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final width in <double>[320, 400]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

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

        expect(
          tester.takeException(),
          isNull,
          reason: '寬度 $width 時不應發生 overflow',
        );
        expect(find.text('SignUp'), findsOneWidget);
        expect(find.text('Continue As Guest'), findsOneWidget);
      }
    });
  });
}
