import '../../data_layer/dto/dto_barrel.dart';

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
