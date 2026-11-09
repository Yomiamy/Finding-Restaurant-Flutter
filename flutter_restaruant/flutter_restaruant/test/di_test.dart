import 'package:flutter/services.dart';
import 'package:flutter_inspector_kit/flutter_inspector_kit.dart';
import 'package:flutter_restaruant/api/api_barrel.dart';

import 'package:flutter_restaruant/data_layer/datasources/datasources_barrel.dart';
import 'package:flutter_restaruant/app/di/di_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/features/manager/manager_barrel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
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

    test('FavorDataSource resolves and is shared by all repositories', () {
      expect(GetIt.I.isRegistered<FavorDataSource>(), isTrue);

      final dataSource1 = GetIt.I<FavorDataSource>();
      final dataSource2 = GetIt.I<FavorDataSource>();
      expect(identical(dataSource1, dataSource2), isTrue);
    });

    test('MainRepository resolves to MainRepository', () {
      expect(GetIt.I.isRegistered<MainRepository>(), isTrue);
      final repo = GetIt.I<MainRepository>();
      expect(repo, isA<MainRepository>());
      expect(repo, isA<MainRepository>());
    });

    test(
      'RestaurantDetailRepository resolves to RestaurantDetailRepository',
      () {
        expect(GetIt.I.isRegistered<RestaurantDetailRepository>(), isTrue);
        final repo = GetIt.I<RestaurantDetailRepository>();
        expect(repo, isA<RestaurantDetailRepository>());
        expect(repo, isA<RestaurantDetailRepository>());
      },
    );

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
    });

    test('MenuVisionRepository resolves to MenuVisionRepository', () {
      expect(GetIt.I.isRegistered<MenuVisionRepository>(), isTrue);
      final repo = GetIt.I<MenuVisionRepository>();
      expect(repo, isA<MenuVisionRepository>());
    });

    test('AiFoodieRepository resolves to AiFoodieRepository', () {
      expect(GetIt.I.isRegistered<AiFoodieRepository>(), isTrue);
      final repo = GetIt.I<AiFoodieRepository>();
      expect(repo, isA<AiFoodieRepository>());
    });

    test('ReviewSummaryRepository resolves to ReviewSummaryRepository', () {
      expect(GetIt.I.isRegistered<ReviewSummaryRepository>(), isTrue);
      final repo = GetIt.I<ReviewSummaryRepository>();
      expect(repo, isA<ReviewSummaryRepository>());
    });

    test('YelpBusinessRepository resolves to YelpBusinessRepository', () {
      expect(GetIt.I.isRegistered<YelpBusinessRepository>(), isTrue);
      final repo = GetIt.I<YelpBusinessRepository>();
      expect(repo, isA<YelpBusinessRepository>());
    });

    test('YelpEventRepository resolves to YelpEventRepository', () {
      expect(GetIt.I.isRegistered<YelpEventRepository>(), isTrue);
      final repo = GetIt.I<YelpEventRepository>();
      expect(repo, isA<YelpEventRepository>());
    });

    test('YelpCategoryRepository resolves to YelpCategoryRepository', () {
      expect(GetIt.I.isRegistered<YelpCategoryRepository>(), isTrue);
      final repo = GetIt.I<YelpCategoryRepository>();
      expect(repo, isA<YelpCategoryRepository>());
    });

    test(
      'YelpAutocompleteRepository resolves to YelpAutocompleteRepository',
      () {
        expect(GetIt.I.isRegistered<YelpAutocompleteRepository>(), isTrue);
        final repo = GetIt.I<YelpAutocompleteRepository>();
        expect(repo, isA<YelpAutocompleteRepository>());
      },
    );

    test('UgcNoteRepository resolves to UgcNoteRepository', () {
      expect(GetIt.I.isRegistered<UgcNoteDataSource>(), isTrue);
      expect(GetIt.I<UgcNoteDataSource>(), isA<UgcNoteDataSource>());

      expect(GetIt.I.isRegistered<UgcNoteRepository>(), isTrue);
      final repo = GetIt.I<UgcNoteRepository>();
      expect(repo, isA<UgcNoteRepository>());
    });

    test('Lazy singletons return the same instance', () {
      final mainRepo1 = GetIt.I<MainRepository>();
      final mainRepo2 = GetIt.I<MainRepository>();
      expect(identical(mainRepo1, mainRepo2), isTrue);

      final favorRepo1 = GetIt.I<FavorRepository>();
      final favorRepo2 = GetIt.I<FavorRepository>();
      expect(identical(favorRepo1, favorRepo2), isTrue);

      final reviewSummaryRepo1 = GetIt.I<ReviewSummaryRepository>();
      final reviewSummaryRepo2 = GetIt.I<ReviewSummaryRepository>();
      expect(identical(reviewSummaryRepo1, reviewSummaryRepo2), isTrue);
    });

    test(
      'SharedPreferencesSource performs CRUD on key-value storage',
      () async {
        SharedPreferences.setMockInitialValues({
          'string_key': 'hello',
          'int_key': 42,
          'double_key': 3.14,
          'bool_key': true,
          'list_key': ['a', 'b'],
        });
        final prefs = await SharedPreferences.getInstance();
        final source = SharedPreferencesSource(prefs);

        expect(source.name, 'SharedPreferences');

        // listAll & type mappings
        final entries = await source.listAll();
        expect(entries.length, 5);
        expect(
          entries.firstWhere((e) => e.key == 'string_key').type,
          KeyValueType.string,
        );
        expect(
          entries.firstWhere((e) => e.key == 'int_key').type,
          KeyValueType.int,
        );
        expect(
          entries.firstWhere((e) => e.key == 'double_key').type,
          KeyValueType.double,
        );
        expect(
          entries.firstWhere((e) => e.key == 'bool_key').type,
          KeyValueType.bool,
        );
        expect(
          entries.firstWhere((e) => e.key == 'list_key').type,
          KeyValueType.stringList,
        );

        // setValue updates
        await source.setValue('string_key', 'world');
        expect(prefs.getString('string_key'), 'world');

        await source.setValue('int_key', 100);
        expect(prefs.getInt('int_key'), 100);

        await source.setValue('double_key', 2.718);
        expect(prefs.getDouble('double_key'), 2.718);

        await source.setValue('bool_key', false);
        expect(prefs.getBool('bool_key'), false);

        await source.setValue('list_key', ['x', 'y']);
        expect(prefs.getStringList('list_key'), ['x', 'y']);

        // remove
        await source.remove('string_key');
        expect(prefs.containsKey('string_key'), isFalse);

        // clear
        await source.clear();
        expect(prefs.getKeys(), isEmpty);
      },
    );

    test(
      'registerSharedPreferencesSource registers source to inspector',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await registerSharedPreferencesSource(prefs);
        expect(
          inspector?.keyValueSources.any((s) => s.name == 'SharedPreferences'),
          isTrue,
        );
      },
    );
  });
}
