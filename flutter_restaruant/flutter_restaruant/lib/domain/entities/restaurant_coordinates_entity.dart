import '../../data_layer/dto/yelp_restaurant_coordinates_dto.dart';

class RestaurantCoordinatesEntity {
  final double? latitude;
  final double? longitude;

  const RestaurantCoordinatesEntity({
    this.latitude,
    this.longitude,
  });

  factory RestaurantCoordinatesEntity.fromDto(
          YelpRestaurantCoordinatesDto dto) =>
      RestaurantCoordinatesEntity(
        latitude: dto.latitude,
        longitude: dto.longitude,
      );

  YelpRestaurantCoordinatesDto get toDto => YelpRestaurantCoordinatesDto(
        latitude: latitude,
        longitude: longitude,
      );
}

