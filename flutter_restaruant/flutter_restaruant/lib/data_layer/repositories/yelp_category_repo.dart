import 'package:get_it/get_it.dart';

import '../../api/api_barrel.dart';
import '../../app/constants/constants_barrel.dart';
import '../../domain/repositories/yelp_category_repository.dart';

class YelpCategoryRepo implements YelpCategoryRepository {
  final APIClz _api;

  YelpCategoryRepo({APIClz? api}) : _api = api ?? GetIt.I<APIClz>();

  @override
  Future<YelpCategoryListDto> fetchCategories() =>
      _api.categories(Constants.locale);

  @override
  Future<YelpCategoryDetailDto> fetchCategory(String alias) =>
      _api.category(alias, Constants.locale);
}
