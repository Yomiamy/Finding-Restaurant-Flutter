import '../../data_layer/dto/dto_barrel.dart';
import 'restaurant_category_entity.dart';
import 'restaurant_coordinates_entity.dart';
import 'restaurant_location_entity.dart';

class RestaurantEntity {
  final String? id;
  final String? name;
  final String? imageUrl;
  final int? reviewCount;
  final double? rating;
  final String? price;
  final String? phone;
  final double? distance;
  final List<RestaurantCategoryEntity>? categories;
  final RestaurantLocationEntity? location;
  final RestaurantCoordinatesEntity? coordinates;
  final bool favor;

  const RestaurantEntity({
    this.id,
    this.name,
    this.imageUrl,
    this.reviewCount,
    this.rating,
    this.price,
    this.phone,
    this.distance,
    this.categories,
    this.location,
    this.coordinates,
    this.favor = false,
  });

  factory RestaurantEntity.fromDto(YelpRestaurantSummaryDto dto) =>
      RestaurantEntity(
        id: dto.id,
        name: dto.name,
        imageUrl: dto.imageUrl,
        reviewCount: dto.reviewCount,
        rating: dto.rating,
        price: dto.price,
        phone: dto.phone,
        distance: dto.distance,
        categories: dto.categories
            ?.map((e) => RestaurantCategoryEntity.fromDto(e))
            .toList(),
        location: dto.location != null
            ? RestaurantLocationEntity.fromDto(dto.location!)
            : null,
        coordinates: dto.coordinates != null
            ? RestaurantCoordinatesEntity.fromDto(dto.coordinates!)
            : null,
        favor: dto.favor,
      );

  YelpRestaurantSummaryDto get toDto => YelpRestaurantSummaryDto(
        id: id,
        name: name,
        imageUrl: imageUrl,
        reviewCount: reviewCount,
        rating: rating,
        price: price,
        phone: phone,
        distance: distance,
        categories: categories?.map((e) => e.toDto).toList(),
        location: location?.toDto,
        coordinates: coordinates?.toDto,
        favor: favor,
      );

  String get categoriesStr =>
      categories?.map((category) => category.title ?? '').join(' ') ?? '';

  RestaurantEntity copyWith({
    String? id,
    String? name,
    String? imageUrl,
    int? reviewCount,
    double? rating,
    String? price,
    String? phone,
    double? distance,
    List<RestaurantCategoryEntity>? categories,
    RestaurantLocationEntity? location,
    RestaurantCoordinatesEntity? coordinates,
    bool? favor,
  }) {
    return RestaurantEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      reviewCount: reviewCount ?? this.reviewCount,
      rating: rating ?? this.rating,
      price: price ?? this.price,
      phone: phone ?? this.phone,
      distance: distance ?? this.distance,
      categories: categories ?? this.categories,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      favor: favor ?? this.favor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RestaurantEntity) return false;
    return id != null && id == other.id;
  }

  @override
  int get hashCode => id?.hashCode ?? 0;
}
