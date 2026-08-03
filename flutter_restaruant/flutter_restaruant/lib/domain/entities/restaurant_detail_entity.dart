import '../../data_layer/dto/dto_barrel.dart';
import 'restaurant_category_entity.dart';
import 'restaurant_coordinates_entity.dart';
import 'restaurant_hours_entity.dart';
import 'restaurant_location_entity.dart';

class RestaurantDetailEntity {
  final String? name;
  final String? imageUrl;
  final bool? isClosed;
  final int? reviewCount;
  final double? rating;
  final String? phone;
  final List<RestaurantCategoryEntity>? categories;
  final RestaurantLocationEntity? location;
  final RestaurantCoordinatesEntity? coordinates;
  final List<String>? photos;
  final List<RestaurantHoursEntity>? hours;

  const RestaurantDetailEntity({
    this.name,
    this.imageUrl,
    this.isClosed,
    this.reviewCount,
    this.rating,
    this.phone,
    this.categories,
    this.location,
    this.coordinates,
    this.photos,
    this.hours,
  });

  factory RestaurantDetailEntity.fromDto(YelpRestaurantDetailDto dto) =>
      RestaurantDetailEntity(
        name: dto.name,
        imageUrl: dto.imageUrl,
        isClosed: dto.isClosed,
        reviewCount: dto.reviewCount,
        rating: dto.rating,
        phone: dto.phone,
        categories: dto.categories
            ?.map((e) => RestaurantCategoryEntity.fromDto(e))
            .toList(),
        location: dto.location != null
            ? RestaurantLocationEntity.fromDto(dto.location!)
            : null,
        coordinates: dto.coordinates != null
            ? RestaurantCoordinatesEntity.fromDto(dto.coordinates!)
            : null,
        photos: dto.photos,
        hours: dto.hours?.map((e) => RestaurantHoursEntity.fromDto(e)).toList(),
      );

  YelpRestaurantDetailDto get toDto => YelpRestaurantDetailDto(
        name: name,
        imageUrl: imageUrl,
        isClosed: isClosed,
        reviewCount: reviewCount,
        rating: rating,
        phone: phone,
        categories: categories?.map((e) => e.toDto).toList(),
        location: location?.toDto,
        coordinates: coordinates?.toDto,
        photos: photos,
        hours: hours?.map((e) => e.toDto).toList(),
      );
}
