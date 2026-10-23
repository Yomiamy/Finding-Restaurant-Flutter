import 'package:flutter_restaruant/api/api_barrel.dart';
import 'package:flutter_restaruant/app/constants/constants_barrel.dart';
import 'package:flutter_restaruant/data_layer/repositories/yelp_autocomplete_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAPIClz extends Mock implements APIClz {}

class _Data {
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
    repo = YelpAutocompleteRepo(api: api);
  });

  group('參數轉發與原樣回傳', () {
    test('autocomplete 帶入 text、Constants.locale 與座標', () async {
      Future<YelpAutocompleteDto> apiCall() => api.autocomplete(
        _Data.text,
        locale: Constants.locale,
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
