import '../entities/entities_barrel.dart';

abstract interface class MainRepository {
  Set<RestaurantEntity> get summaryInfoSet;

  void reset();

  /// 查詢 Yelp 搜尋結果清單。
  ///
  /// [categories] 逗號分隔的 Yelp 分類別名。
  /// [radius] 搜尋半徑（公尺，上限 40,000）。
  /// [openNow] 是否僅搜尋目前營業中（若為 true 則不帶 openAt）。
  Future<List<RestaurantEntity>> fetchYelpSearchInfo({
    double? lat,
    double? lng,
    String? location,
    String? price,
    int? openAt,
    String? sortByStr,
    String? term,
    String? categories,
    int? radius,
    bool? openNow,
  });

  /// Returns the persisted entity so callers adopt the new favor value
  /// instead of deriving it a second time.
  Future<RestaurantEntity> toggleFavor(RestaurantEntity summaryInfo);
}
