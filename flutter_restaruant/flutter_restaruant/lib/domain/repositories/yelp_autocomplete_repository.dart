import '../../api/dto/dto_barrel.dart';

/// Yelp Places API 中以 Autocomplete 為主資源的端點。
///
/// HTTP 失敗原樣拋出 `DioException`，不做轉換；回應格式不符時拋 `CheckedFromJsonException`。
abstract interface class YelpAutocompleteRepository {
  /// `GET /v3/autocomplete`；[text] 至少 1 字元（不在 client 端驗證）。
  Future<YelpAutocompleteDto> autocomplete(
    String text, {
    double? latitude,
    double? longitude,
  });
}
