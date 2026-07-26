import '../../data_layer/dto/yelp_restaurant_business_time_dto.dart';
import '../../utils/utils.dart';

class RestaurantBusinessTimeEntity {
  final bool? isOvernight;
  final String? start;
  final String? end;
  final int? day;

  const RestaurantBusinessTimeEntity({
    this.isOvernight,
    this.start,
    this.end,
    this.day,
  });

  factory RestaurantBusinessTimeEntity.fromDto(
          YelpRestaurantBusinessTimeDto dto) =>
      RestaurantBusinessTimeEntity(
        isOvernight: dto.isOvernight,
        start: dto.start,
        end: dto.end,
        day: dto.day,
      );

  YelpRestaurantBusinessTimeDto get toDto => YelpRestaurantBusinessTimeDto(
        isOvernight: isOvernight,
        start: start,
        end: end,
        day: day,
      );


  String get dayStr => getWeekDayStrByIndex(day ?? 0);

  static String getWeekDayStrByIndex(int day) {
    bool isLocaleZh = Utils.isLocaleZh();

    switch (day) {
      case 0:
        return isLocaleZh ? '星期一' : 'Monday';
      case 1:
        return isLocaleZh ? '星期二' : 'Tuesday';
      case 2:
        return isLocaleZh ? '星期三' : 'Wednesday';
      case 3:
        return isLocaleZh ? '星期四' : 'Thursday';
      case 4:
        return isLocaleZh ? '星期五' : 'Friday';
      case 5:
        return isLocaleZh ? '星期六' : 'Saturday';
      case 6:
        return isLocaleZh ? '星期日' : 'Sunday';
    }
    return '';
  }
}
