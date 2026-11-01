import 'dart:async';

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

      expect(cuisines, repo.defaultCuisines);
      expect(cuisines.isNotEmpty, isTrue);
    });

    test('遠端分類為空時優雅降級為 defaultCuisines', () async {
      Future<YelpCategoryListDto> apiCall() => api.categories(_Data.locale);
      when(apiCall).thenAnswer((_) async => _Data.emptyList);

      final cuisines = await repo.fetchCuisineCategories();

      expect(cuisines, repo.defaultCuisines);
    });

    test('API 回應解析拋出 TypeError 時優雅降級為 defaultCuisines', () async {
      Future<YelpCategoryListDto> apiCall() => api.categories(_Data.locale);
      when(apiCall).thenAnswer((_) => throw TypeError());

      final cuisines = await repo.fetchCuisineCategories();

      expect(cuisines, repo.defaultCuisines);
    });

    test('在途請求進行中若傳入 forceRefresh: true，應發起新請求而非返回舊請求', () async {
      int callCount = 0;
      when(() => api.categories(_Data.locale)).thenAnswer((_) async {
        callCount++;
        return _Data.mixedList;
      });

      final first = repo.fetchCategories();
      final forced = repo.fetchCategories(forceRefresh: true);

      await Future.wait([first, forced]);
      expect(callCount, 2);
    });

    test('遠端回傳空列表時不快取空結果，後續呼叫仍重新請求 API', () async {
      int callCount = 0;
      when(() => api.categories(_Data.locale)).thenAnswer((_) async {
        callCount++;
        return _Data.emptyList;
      });

      await repo.fetchCategories();
      await repo.fetchCategories();

      expect(callCount, 2);
    });

    test('較早發起之請求較晚完成時，不覆蓋 forceRefresh 之更新快取', () async {
      final slowCompleter = Completer<YelpCategoryListDto>();
      final fastCompleter = Completer<YelpCategoryListDto>();

      int callIndex = 0;
      when(() => api.categories(_Data.locale)).thenAnswer((_) {
        callIndex++;
        if (callIndex == 1) {
          return slowCompleter.future;
        }
        return fastCompleter.future;
      });

      final slowFetch = repo.fetchCategories();
      final forcedFetch = repo.fetchCategories(forceRefresh: true);

      // 強制重整先完成
      fastCompleter.complete(_Data.mixedList);
      final forcedResult = await forcedFetch;

      // 舊請求後完成
      slowCompleter.complete(_Data.emptyList);
      await slowFetch;

      // 再次取得快取應為 mixedList 而非被舊請求覆蓋
      final cachedResult = await repo.fetchCategories();
      expect(cachedResult.categories, _Data.mixedList.categories);
      expect(forcedResult.categories, _Data.mixedList.categories);
    });

    test('較早發起之 fetchCuisineCategories 較晚完成時，不覆蓋 forceRefresh 之菜系快取', () async {
      final slowCompleter = Completer<YelpCategoryListDto>();
      final fastCompleter = Completer<YelpCategoryListDto>();

      int callIndex = 0;
      when(() => api.categories(_Data.locale)).thenAnswer((_) {
        callIndex++;
        if (callIndex == 1) {
          return slowCompleter.future;
        }
        return fastCompleter.future;
      });

      final slowFetch = repo.fetchCuisineCategories();
      final forcedFetch = repo.fetchCuisineCategories(forceRefresh: true);

      // 強制重整先完成（回傳 mixedList，過濾後包含 japanese, desserts）
      fastCompleter.complete(_Data.mixedList);
      final forcedResult = await forcedFetch;

      // 舊請求後完成（回傳空清單，若覆蓋快取將變成 defaultCuisines）
      slowCompleter.complete(_Data.emptyList);
      await slowFetch;

      // 再次取得快取應仍為 forcedResult 而非被舊請求覆蓋
      final cachedResult = await repo.fetchCuisineCategories();
      expect(cachedResult, same(forcedResult));
      expect(
        cachedResult.map((e) => e.alias),
        containsAll(['japanese', 'desserts']),
      );
    });
  });

  group('defaultCuisines 多語系兜底', () {
    test('en 語系回傳英文標題', () {
      final enRepo = YelpCategoryRepo(api: api, locale: 'en_US');
      expect(enRepo.defaultCuisines, YelpCategoryRepo.defaultCuisinesEn);
      expect(enRepo.defaultCuisines.first.title, 'Taiwanese');
    });

    test('zh 或其他語系回傳繁中標題', () {
      final zhRepo = YelpCategoryRepo(api: api, locale: 'zh_TW');
      expect(zhRepo.defaultCuisines, YelpCategoryRepo.defaultCuisinesZh);
      expect(zhRepo.defaultCuisines.first.title, '台灣小吃');
    });
  });
}
