import 'package:dio/dio.dart';
import 'package:flutter_restaruant/api/api_barrel.dart';
import 'package:flutter_restaruant/data_layer/repositories/yelp_category_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAPIClz extends Mock implements APIClz {}

class _Data {
  static const String locale = 'en_US';
  static const String alias = 'pizza';

  static const YelpCategoryListDto emptyList = YelpCategoryListDto(
    categories: [],
  );

  static const YelpCategoryListDto mixedList = YelpCategoryListDto(
    categories: [
      YelpRestaurantCategoryDto(
        alias: 'japanese',
        title: '日式料理',
        parentAliases: ['restaurants'],
      ),
      YelpRestaurantCategoryDto(
        alias: 'auto_repair',
        title: '汽車維修',
        parentAliases: ['auto'],
      ),
      YelpRestaurantCategoryDto(
        alias: 'desserts',
        title: '甜點',
        parentAliases: ['food'],
      ),
    ],
  );

  static const YelpCategoryDetailDto detail = YelpCategoryDetailDto(
    category: YelpRestaurantCategoryDto(alias: alias),
  );
}

void main() {
  late _MockAPIClz api;
  late YelpCategoryRepo repo;

  setUp(() {
    api = _MockAPIClz();
    repo = YelpCategoryRepo(api: api, locale: _Data.locale);
  });

  group('參數轉發與原樣回傳', () {
    test('fetchCategories 帶入注入的 locale', () async {
      Future<YelpCategoryListDto> apiCall() => api.categories(_Data.locale);
      when(apiCall).thenAnswer((_) async => _Data.emptyList);

      final result = await repo.fetchCategories();

      expect(result, same(_Data.emptyList));
      verify(apiCall).called(1);
    });

    test('fetchCategory 帶入 alias 與注入的 locale', () async {
      Future<YelpCategoryDetailDto> apiCall() =>
          api.category(_Data.alias, _Data.locale);
      when(apiCall).thenAnswer((_) async => _Data.detail);

      final result = await repo.fetchCategory(_Data.alias);

      expect(result, same(_Data.detail));
      verify(apiCall).called(1);
    });
  });

  group('記憶體快取與菜系過濾', () {
    test('第二次呼叫 fetchCategories 命中快取，不重打 API', () async {
      Future<YelpCategoryListDto> apiCall() => api.categories(_Data.locale);
      when(apiCall).thenAnswer((_) async => _Data.mixedList);

      final first = await repo.fetchCategories();
      final second = await repo.fetchCategories();

      expect(first.categories, _Data.mixedList.categories);
      expect(second.categories, _Data.mixedList.categories);
      verify(apiCall).called(1);
    });

    test('forceRefresh 為 true 時強制重新發送 API 請求並更新快取', () async {
      Future<YelpCategoryListDto> apiCall() => api.categories(_Data.locale);
      when(apiCall).thenAnswer((_) async => _Data.mixedList);

      await repo.fetchCategories();
      await repo.fetchCategories(forceRefresh: true);

      verify(apiCall).called(2);
    });

    test('fetchCuisineCategories 正確過濾 restaurants 與 food 子類別', () async {
      Future<YelpCategoryListDto> apiCall() => api.categories(_Data.locale);
      when(apiCall).thenAnswer((_) async => _Data.mixedList);

      final cuisines = await repo.fetchCuisineCategories();

      expect(cuisines.length, 2);
      expect(
        cuisines.map((e) => e.alias),
        containsAll(['japanese', 'desserts']),
      );
      expect(cuisines.map((e) => e.alias), isNot(contains('auto_repair')));
      verify(apiCall).called(1);

      // 第二次呼叫命中快取
      final second = await repo.fetchCuisineCategories();
      expect(second, same(cuisines));
      verifyNoMoreInteractions(api);
    });

    test('API 拋出 DioException 時優雅降級為 defaultCuisines', () async {
      Future<YelpCategoryListDto> apiCall() => api.categories(_Data.locale);
      when(apiCall).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v3/categories'),
          error: 'Connection timed out',
        ),
      );

      final cuisines = await repo.fetchCuisineCategories();

      expect(cuisines, YelpCategoryRepo.defaultCuisines);
      expect(cuisines.isNotEmpty, isTrue);
    });

    test('遠端分類為空時優雅降級為 defaultCuisines', () async {
      Future<YelpCategoryListDto> apiCall() => api.categories(_Data.locale);
      when(apiCall).thenAnswer((_) async => _Data.emptyList);

      final cuisines = await repo.fetchCuisineCategories();

      expect(cuisines, YelpCategoryRepo.defaultCuisines);
    });
  });
}
