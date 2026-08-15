import '../../data_layer/dto/dto_barrel.dart';
import 'restaurant_business_time_entity.dart';

class RestaurantHoursEntity {
  final bool? isOpenNow;
  final String? hoursType;
  final List<RestaurantBusinessTimeEntity>? open;

  const RestaurantHoursEntity({this.isOpenNow, this.hoursType, this.open});

  factory RestaurantHoursEntity.fromDto(YelpRestaurantHoursDto dto) =>
      RestaurantHoursEntity(
        isOpenNow: dto.isOpenNow,
        hoursType: dto.hoursType,
        open: dto.open
            ?.map((e) => RestaurantBusinessTimeEntity.fromDto(e))
            .toList(),
      );

  YelpRestaurantHoursDto get toDto => YelpRestaurantHoursDto(
    isOpenNow: isOpenNow,
    hoursType: hoursType,
    open: open?.map((e) => e.toDto).toList(),
  );
}
