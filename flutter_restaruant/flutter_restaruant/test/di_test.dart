import 'package:flutter/services.dart';
import 'package:flutter_restaruant/api/api_clz.dart';
import 'package:flutter_restaruant/api/dio/dio_client.dart';

import 'package:flutter_restaruant/di/injection.dart';
import 'package:flutter_restaruant/domain/repositories/favor_repository.dart';
import 'package:flutter_restaruant/domain/repositories/main_repository.dart';
import 'package:flutter_restaruant/domain/repositories/restaurant_detail_repository.dart';
import 'package:flutter_restaruant/domain/repositories/settings_repository.dart';
import 'package:flutter_restaruant/domain/repositories/sign_in_repository.dart';
import 'package:flutter_restaruant/manager/ad_counter_manager.dart';
import 'package:flutter_restaruant/manager/fcm_manager.dart';
import 'package:flutter_restaruant/manager/sign_in_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/local_auth');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getAvailableBiometrics') {
        return <String>[];
      }
      return null;
    });

    await GetIt.I.reset();
    setupInjection();
  });

  group('Dependency Injection Tests via GetIt', () {
    test('Network services resolve correctly', () {
      expect(GetIt.I.isRegistered<DioClient>(), isTrue);
      expect(GetIt.I<DioClient>(), isNotNull);

      expect(GetIt.I.isRegistered<APIClz>(), isTrue);
      expect(GetIt.I<APIClz>(), isNotNull);
    });

    test('Managers resolve correctly', () {
      expect(GetIt.I.isRegistered<SignInManager>(), isTrue);
      expect(GetIt.I<SignInManager>(), isA<SignInManager>());

      expect(GetIt.I.isRegistered<FcmManager>(), isTrue);
      expect(GetIt.I<FcmManager>(), isA<FcmManager>());

      expect(GetIt.I.isRegistered<AdCounterManager>(), isTrue);
      expect(GetIt.I<AdCounterManager>(), isA<AdCounterManager>());
    });

    test('MainRepository resolves to MainRepository', () {
      expect(GetIt.I.isRegistered<MainRepository>(), isTrue);
      final repo = GetIt.I<MainRepository>();
      expect(repo, isA<MainRepository>());
      expect(repo, isA<MainRepository>());
    });

    test('RestaurantDetailRepository resolves to RestaurantDetailRepository',
        () {
      expect(GetIt.I.isRegistered<RestaurantDetailRepository>(), isTrue);
      final repo = GetIt.I<RestaurantDetailRepository>();
      expect(repo, isA<RestaurantDetailRepository>());
      expect(repo, isA<RestaurantDetailRepository>());
    });

    test('FavorRepository resolves to FavorRepository', () {
      expect(GetIt.I.isRegistered<FavorRepository>(), isTrue);
      final repo = GetIt.I<FavorRepository>();
      expect(repo, isA<FavorRepository>());
      expect(repo, isA<FavorRepository>());
    });

    test('SignInRepository resolves to SignInRepository', () {
      expect(GetIt.I.isRegistered<SignInRepository>(), isTrue);
      final repo = GetIt.I<SignInRepository>();
      expect(repo, isA<SignInRepository>());
      expect(repo, isA<SignInRepository>());
    });

    test('SettingsRepository resolves to SettingsRepository', () {
      expect(GetIt.I.isRegistered<SettingsRepository>(), isTrue);
      final repo = GetIt.I<SettingsRepository>();
      expect(repo, isA<SettingsRepository>());
      expect(repo, isA<SettingsRepository>());
    });

    test('Lazy singletons return the same instance', () {
      final mainRepo1 = GetIt.I<MainRepository>();
      final mainRepo2 = GetIt.I<MainRepository>();
      expect(identical(mainRepo1, mainRepo2), isTrue);

      final favorRepo1 = GetIt.I<FavorRepository>();
      final favorRepo2 = GetIt.I<FavorRepository>();
      expect(identical(favorRepo1, favorRepo2), isTrue);
    });
  });
}
