import '../../api/api_barrel.dart';
import '../../domain/repositories/yelp_category_repository.dart';

class YelpCategoryRepo implements YelpCategoryRepository {
  final APIClz _api;
  final String _locale;

  List<YelpRestaurantCategoryDto>? _cachedCategories;
  List<YelpRestaurantCategoryDto>? _cachedCuisineCategories;
  Future<YelpCategoryListDto>? _inFlightFetch;
  int _fetchGeneration = 0;

  static const List<YelpRestaurantCategoryDto> defaultCuisinesZh = [
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

  static const List<YelpRestaurantCategoryDto> defaultCuisinesEn = [
    YelpRestaurantCategoryDto(alias: 'taiwanese', title: 'Taiwanese'),
    YelpRestaurantCategoryDto(alias: 'japanese', title: 'Japanese'),
    YelpRestaurantCategoryDto(alias: 'italian', title: 'Italian'),
    YelpRestaurantCategoryDto(alias: 'chinese', title: 'Chinese'),
    YelpRestaurantCategoryDto(alias: 'korean', title: 'Korean'),
    YelpRestaurantCategoryDto(alias: 'tradamerican', title: 'American'),
    YelpRestaurantCategoryDto(alias: 'hotpot', title: 'Hot Pot'),
    YelpRestaurantCategoryDto(alias: 'cafes', title: 'Cafes'),
    YelpRestaurantCategoryDto(alias: 'desserts', title: 'Desserts'),
    YelpRestaurantCategoryDto(alias: 'bars', title: 'Bars & Pubs'),
  ];

  @override
  List<YelpRestaurantCategoryDto> get defaultCuisines =>
      _locale.startsWith('en') ? defaultCuisinesEn : defaultCuisinesZh;

  YelpCategoryRepo({required APIClz api, required String locale})
    : _api = api,
      _locale = locale;

  @override
  Future<YelpCategoryListDto> fetchCategories({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      _cachedCategories = null;
      _cachedCuisineCategories = null;
    } else {
      if (_cachedCategories != null) {
        return YelpCategoryListDto(categories: _cachedCategories);
      }
      if (_inFlightFetch != null) {
        return _inFlightFetch!;
      }
    }

    final generation = ++_fetchGeneration;
    final future = _api.categories(_locale);
    _inFlightFetch = future;
    try {
      final dto = await future;
      if (generation == _fetchGeneration &&
          dto.categories != null &&
          dto.categories!.isNotEmpty) {
        _cachedCategories = dto.categories;
      }
      return dto;
    } finally {
      if (generation == _fetchGeneration) {
        _inFlightFetch = null;
      }
    }
  }

  @override
  Future<List<YelpRestaurantCategoryDto>> fetchCuisineCategories({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      _cachedCuisineCategories = null;
    } else if (_cachedCuisineCategories != null) {
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
        return defaultCuisines;
      }
      _cachedCuisineCategories = cuisines;
      return _cachedCuisineCategories!;
    } on Exception {
      // 網路或 API 例外時優雅降級為 defaultCuisines，不賦值給快取以利後續重試
      return defaultCuisines;
    } on TypeError {
      // API 回應空 body 或資料欄位型別不合時優雅降級為 defaultCuisines
      return defaultCuisines;
    }
  }

  @override
  Future<YelpCategoryDetailDto> fetchCategory(String alias) =>
      _api.category(alias, _locale);
}
