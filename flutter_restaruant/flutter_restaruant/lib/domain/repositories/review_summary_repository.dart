import '../entities/entities_barrel.dart';

/// 餐廳評論智慧摘要倉儲契約
abstract interface class ReviewSummaryRepository {
  /// 根據餐廳詳細資料與顧客短評列表生成結構化評論情報
  Future<ReviewSummaryEntity> generateReviewSummary({
    required RestaurantDetailEntity detail,
    required List<ReviewDetailEntity> reviews,
  });
}
