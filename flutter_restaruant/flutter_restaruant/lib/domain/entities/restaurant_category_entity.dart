import '../../data_layer/dto/yelp_restaurant_category_dto.dart';

class RestaurantCategoryEntity {
  final String? alias;
  final String? title;

  const RestaurantCategoryEntity({
    this.alias,
    this.title,
  });

  factory RestaurantCategoryEntity.fromDto(YelpRestaurantCategoryDto dto) =>
      RestaurantCategoryEntity(
        alias: dto.alias,
        title: dto.title,
      );

  YelpRestaurantCategoryDto get toDto => YelpRestaurantCategoryDto(
        alias: alias,
        title: title,
      );
}

