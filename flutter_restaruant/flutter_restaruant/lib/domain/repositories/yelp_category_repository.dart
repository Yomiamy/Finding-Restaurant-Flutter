import '../../api/dto/dto_barrel.dart';

/// Yelp Places API 中以 Category 為主資源的端點。
///
/// 所有方法失敗時原樣拋出 `DioException`，不做轉換。
abstract interface class YelpCategoryRepository {
  /// `GET /v3/categories`；固定帶 `Constants.locale`，
  /// Yelp 只回傳該 locale 可用的分類並翻譯標題。
  Future<YelpCategoryListDto> fetchCategories();

  /// `GET /v3/categories/{alias}`；回傳外殼 DTO，不拆出 `category`。
  Future<YelpCategoryDetailDto> fetchCategory(String alias);
}
