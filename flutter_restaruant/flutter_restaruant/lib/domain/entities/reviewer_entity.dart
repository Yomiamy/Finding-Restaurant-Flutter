import '../../data_layer/dto/dto_barrel.dart';

class ReviewerEntity {
  final String? name;
  final String? imageUrl;

  const ReviewerEntity({this.name, this.imageUrl});

  factory ReviewerEntity.fromDto(YelpReviewerDto dto) =>
      ReviewerEntity(name: dto.name, imageUrl: dto.imageUrl);

  YelpReviewerDto get toDto => YelpReviewerDto(name: name, imageUrl: imageUrl);
}
