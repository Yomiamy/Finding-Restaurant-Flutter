import '../../data_layer/dto/dto_barrel.dart';
import '../../generated/l10n.dart';

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
    YelpRestaurantBusinessTimeDto dto,
  ) => RestaurantBusinessTimeEntity(
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
    try {
      return switch (day) {
        0 => S.current.weekday_monday,
        1 => S.current.weekday_tuesday,
        2 => S.current.weekday_wednesday,
        3 => S.current.weekday_thursday,
        4 => S.current.weekday_friday,
        5 => S.current.weekday_saturday,
        6 => S.current.weekday_sunday,
        _ => '',
      };
    } catch (_) {
      return switch (day) {
        0 => 'Monday',
        1 => 'Tuesday',
        2 => 'Wednesday',
        3 => 'Thursday',
        4 => 'Friday',
        5 => 'Saturday',
        6 => 'Sunday',
        _ => '',
      };
    }
  }
}
