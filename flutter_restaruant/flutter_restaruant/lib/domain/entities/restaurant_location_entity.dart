import '../../data_layer/dto/yelp_restaurant_location_dto.dart';

class RestaurantLocationEntity {
  final String? address1;
  final String? address2;
  final String? address3;
  final String? city;
  final String? country;
  final String? state;
  final List<String>? displayAddress;

  const RestaurantLocationEntity({
    this.address1,
    this.address2,
    this.address3,
    this.city,
    this.country,
    this.state,
    this.displayAddress,
  });

  factory RestaurantLocationEntity.fromDto(YelpRestaurantLocationDto dto) =>
      RestaurantLocationEntity(
        address1: dto.address1,
        address2: dto.address2,
        address3: dto.address3,
        city: dto.city,
        country: dto.country,
        state: dto.state,
        displayAddress: dto.displayAddress,
      );

  YelpRestaurantLocationDto get toDto => YelpRestaurantLocationDto(
        address1: address1,
        address2: address2,
        address3: address3,
        city: city,
        country: country,
        state: state,
        displayAddress: displayAddress,
      );

  String get displayAddressStr => displayAddress?.join('') ?? '';
}

