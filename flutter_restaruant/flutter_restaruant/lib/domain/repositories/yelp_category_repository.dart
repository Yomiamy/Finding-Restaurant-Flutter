import '../../api/dto/dto_barrel.dart';

/// Yelp Places API 中以 Category 為主資源的端點。
///
/// HTTP 失敗原樣拋出 `DioException`，不做轉換；回應格式不符時拋 `CheckedFromJsonException`。
abstract interface class YelpCategoryRepository {
  /// 離線或例外時優雅降級之預設料理分類清單。
  List<YelpRestaurantCategoryDto> get defaultCuisines;

  /// 靜態通用兜底清單。
  static const List<YelpRestaurantCategoryDto> fallbackCuisines = [
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

  /// `GET /v3/categories`；帶建構時注入的 locale，
  /// Yelp 只回傳該 locale 可用的分類並翻譯標題。
  ///
  /// 支援本地記憶體快取，[forceRefresh] 為 true 時才向遠端重新請求。
  Future<YelpCategoryListDto> fetchCategories({bool forceRefresh = false});

  /// 取得餐飲料理分類（篩選 parentAliases 包含 'restaurants' 或 'food' 者）。
  /// 支援本地記憶體快取與異常/離線時優雅降級為內建熱門菜系清單。
  Future<List<YelpRestaurantCategoryDto>> fetchCuisineCategories({
    bool forceRefresh = false,
  });

  /// `GET /v3/categories/{alias}`；回傳外殼 DTO，不拆出 `category`。
  Future<YelpCategoryDetailDto> fetchCategory(String alias);
}
