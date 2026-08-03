import '../../data_layer/dto/dto_barrel.dart';
import 'reviewer_entity.dart';

class ReviewDetailEntity {
  final String? id;
  final double? rating;
  final ReviewerEntity? user;
  final String? text;
  final String? timeCreated;
  final String? url;

  const ReviewDetailEntity({
    this.id,
    this.rating,
    this.user,
    this.text,
    this.timeCreated,
    this.url,
  });

  factory ReviewDetailEntity.fromDto(YelpReviewDetailDto dto) =>
      ReviewDetailEntity(
        id: dto.id,
        rating: dto.rating,
        user: dto.user != null ? ReviewerEntity.fromDto(dto.user!) : null,
        text: dto.text,
        timeCreated: dto.timeCreated,
        url: dto.url,
      );

  YelpReviewDetailDto get toDto => YelpReviewDetailDto(
        id: id,
        rating: rating,
        user: user?.toDto,
        text: text,
        timeCreated: timeCreated,
        url: url,
      );
}
