import 'package:flutter/services.dart';
import 'package:flutter_restaruant/data_layer/repositories/favor_repo.dart';
import 'package:flutter_restaruant/data_layer/repositories/main_repo.dart';
import 'package:flutter_restaruant/data_layer/repositories/restaurant_detail_repo.dart';
import 'package:flutter_restaruant/data_layer/repositories/settings_repo.dart';
import 'package:flutter_restaruant/data_layer/repositories/sign_in_repo.dart';
import 'package:flutter_restaruant/domain/repositories/favor_repository.dart';
import 'package:flutter_restaruant/domain/repositories/main_repository.dart';
import 'package:flutter_restaruant/domain/repositories/restaurant_detail_repository.dart';
import 'package:flutter_restaruant/domain/repositories/settings_repository.dart';
import 'package:flutter_restaruant/domain/repositories/sign_in_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/local_auth');
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
      final repo = MainRepo();
      expect(repo, isA<MainRepository>());
      expect(repo.summaryInfoSet, isEmpty);
      repo.reset();
      expect(repo.summaryInfoSet, isEmpty);
    });

    test('FavorRepository implements FavorRepository', () {
      final repo = FavorRepo();
      expect(repo, isA<FavorRepository>());
    });

    test('RestaurantDetailRepository implements RestaurantDetailRepository',
        () {
      final repo = RestaurantDetailRepo();
      expect(repo, isA<RestaurantDetailRepository>());
    });

    test('SignInRepository implements SignInRepository', () {
      final repo = SignInRepo();
      expect(repo, isA<SignInRepository>());
    });
  });
}
