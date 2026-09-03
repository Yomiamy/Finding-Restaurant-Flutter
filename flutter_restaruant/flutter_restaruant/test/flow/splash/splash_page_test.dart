import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/flow/signinup/view/sign_in_page.dart';
import 'package:flutter_restaruant/flow/splash/view/splash_page.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SplashPage Widget Tests', () {
    testWidgets('渲染主視覺圖片並套用 BoxFit.cover', (tester) async {
      final originalErrorWidgetBuilder = ErrorWidget.builder;
      final originalFlutterErrorOnError = FlutterError.onError;
      final originalPlatformDispatcherOnError =
          ui.PlatformDispatcher.instance.onError;

      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemeData.materialLight,
            localizationsDelegates: const [S.delegate],
            routes: {
              SplashPage.routeName: (_) => const SplashPage(),
              SignInPage.routeName: (_) => const Scaffold(body: Text('SignIn')),
            },
            initialRoute: SplashPage.routeName,
          ),
        );

        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);

        final imageWidget = tester.widget<Image>(imageFinder);
        expect(imageWidget.fit, BoxFit.cover);

        // Drain the 3s splash timer
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      } finally {
        ErrorWidget.builder = originalErrorWidgetBuilder;
        FlutterError.onError = originalFlutterErrorOnError;
        ui.PlatformDispatcher.instance.onError =
            originalPlatformDispatcherOnError;
      }
    });

    testWidgets('3 秒延遲後導向目標登入頁面', (tester) async {
      final originalErrorWidgetBuilder = ErrorWidget.builder;
      final originalFlutterErrorOnError = FlutterError.onError;
      final originalPlatformDispatcherOnError =
          ui.PlatformDispatcher.instance.onError;

      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemeData.materialLight,
            localizationsDelegates: const [S.delegate],
            routes: {
              SplashPage.routeName: (_) => const SplashPage(),
              SignInPage.routeName: (_) => const Scaffold(body: Text('SignIn')),
            },
            initialRoute: SplashPage.routeName,
          ),
        );

        // Advance time by 3 seconds
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        expect(find.text('SignIn'), findsOneWidget);
      } finally {
        ErrorWidget.builder = originalErrorWidgetBuilder;
        FlutterError.onError = originalFlutterErrorOnError;
        ui.PlatformDispatcher.instance.onError =
            originalPlatformDispatcherOnError;
      }
    });
  });
}
