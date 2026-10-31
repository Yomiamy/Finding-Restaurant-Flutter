import '../../api/dto/dto_barrel.dart';

/// Yelp Places API 中以 Category 為主資源的端點。
///
/// HTTP 失敗原樣拋出 `DioException`，不做轉換；回應格式不符時拋 `CheckedFromJsonException`。
abstract interface class YelpCategoryRepository {
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
