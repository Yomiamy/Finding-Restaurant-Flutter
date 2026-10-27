import '../../api/api_barrel.dart';
import '../../domain/repositories/yelp_category_repository.dart';

class YelpCategoryRepo implements YelpCategoryRepository {
  final APIClz _api;
  final String _locale;

  YelpCategoryRepo({required APIClz api, required String locale})
    : _api = api,
      _locale = locale;

  @override
  Future<YelpCategoryListDto> fetchCategories() => _api.categories(_locale);

  @override
  Future<YelpCategoryDetailDto> fetchCategory(String alias) =>
      _api.category(alias, _locale);
}
