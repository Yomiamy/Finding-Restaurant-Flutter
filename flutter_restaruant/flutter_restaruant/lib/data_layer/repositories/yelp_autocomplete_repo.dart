import '../../api/api_barrel.dart';
import '../../domain/repositories/yelp_autocomplete_repository.dart';

class YelpAutocompleteRepo implements YelpAutocompleteRepository {
  final APIClz _api;
  final String _locale;

  YelpAutocompleteRepo({required APIClz api, required String locale})
    : _api = api,
      _locale = locale;

  @override
  Future<YelpAutocompleteDto> autocomplete(
    String text, {
    double? latitude,
    double? longitude,
  }) => _api.autocomplete(
    text,
    locale: _locale,
    latitude: latitude,
    longitude: longitude,
  );
}
