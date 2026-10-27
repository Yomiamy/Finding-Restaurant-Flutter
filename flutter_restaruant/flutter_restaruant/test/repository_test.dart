import 'package:flutter/services.dart';
import 'package:flutter_restaruant/api/api_barrel.dart';
import 'package:flutter_restaruant/data_layer/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAPIClz extends Mock implements APIClz {}

class _Data {
  static const String locale = 'en_US';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel channel = MethodChannel(
      'plugins.flutter.io/local_auth',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getAvailableBiometrics') {
            return <String>[];
          }
          return null;
        });
  });

  group('Repository Architecture Tests', () {
    test('SettingsRepository implements SettingsRepository', () {
      const repo = SettingsRepo();
      expect(repo, isA<SettingsRepository>());
    });

    test('MainRepository implements MainRepository', () {
      final repo = MainRepo(api: _MockAPIClz(), locale: _Data.locale);
      expect(repo, isA<MainRepository>());
      expect(repo.summaryInfoSet, isEmpty);
      repo.reset();
      expect(repo.summaryInfoSet, isEmpty);
    });

    test('FavorRepository implements FavorRepository', () {
      final repo = FavorRepo();
      expect(repo, isA<FavorRepository>());
    });

    test(
      'RestaurantDetailRepository implements RestaurantDetailRepository',
      () {
        final repo = RestaurantDetailRepo(
          api: _MockAPIClz(),
          locale: _Data.locale,
        );
        expect(repo, isA<RestaurantDetailRepository>());
      },
    );

    test('SignInRepository implements SignInRepository', () {
      final repo = SignInRepo();
      expect(repo, isA<SignInRepository>());
    });
  });
}
