import '../../api/dto/dto_barrel.dart';

/// Yelp Places API 中以 Category 為主資源的端點。
///
/// HTTP 失敗原樣拋出 `DioException`，不做轉換；回應格式不符時拋 `CheckedFromJsonException`。
abstract interface class YelpCategoryRepository {
  /// `GET /v3/categories`；帶建構時注入的 locale，
  /// Yelp 只回傳該 locale 可用的分類並翻譯標題。
  Future<YelpCategoryListDto> fetchCategories();

  /// `GET /v3/categories/{alias}`；回傳外殼 DTO，不拆出 `category`。
  Future<YelpCategoryDetailDto> fetchCategory(String alias);
}
