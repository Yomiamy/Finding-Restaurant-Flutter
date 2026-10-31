import 'package:dio/dio.dart';

import '../../api/api_barrel.dart';
import '../../domain/repositories/yelp_category_repository.dart';

class YelpCategoryRepo implements YelpCategoryRepository {
  final APIClz _api;
  final String _locale;

  List<YelpRestaurantCategoryDto>? _cachedCategories;
  List<YelpRestaurantCategoryDto>? _cachedCuisineCategories;

  static const List<YelpRestaurantCategoryDto> defaultCuisines = [
    YelpRestaurantCategoryDto(alias: 'taiwanese', title: '台灣小吃'),
    YelpRestaurantCategoryDto(alias: 'japanese', title: '日式料理'),
    YelpRestaurantCategoryDto(alias: 'italian', title: '義式料理'),
    YelpRestaurantCategoryDto(alias: 'chinese', title: '中式料理'),
    YelpRestaurantCategoryDto(alias: 'korean', title: '韓式料理'),
    YelpRestaurantCategoryDto(alias: 'tradamerican', title: '美式料理'),
    YelpRestaurantCategoryDto(alias: 'hotpot', title: '火鍋'),
    YelpRestaurantCategoryDto(alias: 'cafes', title: '咖啡輕食'),
    YelpRestaurantCategoryDto(alias: 'desserts', title: '甜點冰品'),
    YelpRestaurantCategoryDto(alias: 'bars', title: '酒吧餐酒館'),
  ];

  YelpCategoryRepo({required APIClz api, required String locale})
    : _api = api,
      _locale = locale;

  @override
  Future<YelpCategoryListDto> fetchCategories({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedCategories != null) {
      return YelpCategoryListDto(categories: _cachedCategories);
    }
    final dto = await _api.categories(_locale);
    _cachedCategories = dto.categories;
    return dto;
  }

  @override
  Future<List<YelpRestaurantCategoryDto>> fetchCuisineCategories({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedCuisineCategories != null) {
      return _cachedCuisineCategories!;
    }

    try {
      final dto = await fetchCategories(forceRefresh: forceRefresh);
      final allCategories = dto.categories ?? [];
      final cuisines = allCategories.where((category) {
        final parents = category.parentAliases;
        if (parents == null || parents.isEmpty) return false;
        return parents.contains('restaurants') || parents.contains('food');
      }).toList();

      if (cuisines.isEmpty) {
        _cachedCuisineCategories = defaultCuisines;
      } else {
        _cachedCuisineCategories = cuisines;
      }
      return _cachedCuisineCategories!;
    } on DioException {
      _cachedCuisineCategories = defaultCuisines;
      return _cachedCuisineCategories!;
    } catch (_) {
      _cachedCuisineCategories = defaultCuisines;
      return _cachedCuisineCategories!;
    }
  }

  @override
  Future<YelpCategoryDetailDto> fetchCategory(String alias) =>
      _api.category(alias, _locale);
}
