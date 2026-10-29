import 'package:flutter_restaruant/api/api_barrel.dart';
import 'package:flutter_restaruant/data_layer/repositories/yelp_category_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAPIClz extends Mock implements APIClz {}

class _Data {
  // 刻意不等於正式值 'zh_TW'，才分辨得出轉發的是注入值。
  static const String locale = 'en_US';
  static const String alias = 'pizza';

  static const YelpCategoryListDto list = YelpCategoryListDto(categories: []);
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
      when(apiCall).thenAnswer((_) async => _Data.list);

      final result = await repo.fetchCategories();

      expect(result, same(_Data.list));
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
}
