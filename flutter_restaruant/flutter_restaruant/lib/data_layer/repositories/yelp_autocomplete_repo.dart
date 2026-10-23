import 'package:get_it/get_it.dart';

import '../../api/api_barrel.dart';
import '../../app/constants/constants_barrel.dart';
import '../../domain/repositories/yelp_autocomplete_repository.dart';

class YelpAutocompleteRepo implements YelpAutocompleteRepository {
  final APIClz _api;

  YelpAutocompleteRepo({APIClz? api}) : _api = api ?? GetIt.I<APIClz>();

  @override
  Future<YelpAutocompleteDto> autocomplete(
    String text, {
    double? latitude,
    double? longitude,
  }) => _api.autocomplete(
    text,
    locale: Constants.locale,
    latitude: latitude,
    longitude: longitude,
  );
}
