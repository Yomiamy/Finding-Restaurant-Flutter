import '../../data_layer/dto/dto_barrel.dart';
import 'review_detail_entity.dart';

class ReviewEntity {
  final int? total;
  final List<String>? possibleLanguages;
  final List<ReviewDetailEntity>? reviews;

  const ReviewEntity({
    this.total,
    this.possibleLanguages,
    this.reviews,
  });

  factory ReviewEntity.fromDto(YelpReviewDto dto) => ReviewEntity(
        total: dto.total,
        possibleLanguages: dto.possibleLanguages,
        reviews:
            dto.reviews?.map((e) => ReviewDetailEntity.fromDto(e)).toList(),
      );

  YelpReviewDto get toDto => YelpReviewDto(
        total: total,
        possibleLanguages: possibleLanguages,
        reviews: reviews?.map((e) => e.toDto).toList(),
      );
}
