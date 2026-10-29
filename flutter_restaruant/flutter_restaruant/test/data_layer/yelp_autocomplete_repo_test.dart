import 'package:flutter_restaruant/api/api_barrel.dart';
import 'package:flutter_restaruant/data_layer/repositories/yelp_autocomplete_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAPIClz extends Mock implements APIClz {}

class _Data {
  // 刻意不等於正式值 'zh_TW'，才分辨得出轉發的是注入值。
  static const String locale = 'en_US';
  static const String text = 'piz';

  static const YelpAutocompleteDto suggestions = YelpAutocompleteDto(
    terms: [YelpAutocompleteTermDto(text: 'pizza')],
  );
}

void main() {
  late _MockAPIClz api;
  late YelpAutocompleteRepo repo;

  setUp(() {
    api = _MockAPIClz();
    repo = YelpAutocompleteRepo(api: api, locale: _Data.locale);
  });

  group('參數轉發與原樣回傳', () {
    test('autocomplete 帶入 text、注入的 locale 與座標', () async {
      Future<YelpAutocompleteDto> apiCall() => api.autocomplete(
        _Data.text,
        locale: _Data.locale,
        latitude: 25.03,
        longitude: 121.56,
      );
      when(apiCall).thenAnswer((_) async => _Data.suggestions);

      final result = await repo.autocomplete(
        _Data.text,
        latitude: 25.03,
        longitude: 121.56,
      );

      expect(result, same(_Data.suggestions));
      verify(apiCall).called(1);
    });
  });
}
