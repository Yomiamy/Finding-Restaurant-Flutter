import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'yelp_restaurant_summary_dto.dart';

part 'food_map_item_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class FoodMapItemDto extends Equatable {
  final YelpRestaurantSummaryDto? restaurant;
  final String? addedByUid;
  final String? addedByName;
  final String? note;
  final int? addedAtMs;

  @JsonKey(fromJson: _votesFromJson)
  final Map<String, int> votes;

  const FoodMapItemDto({
    this.restaurant,
    this.addedByUid,
    this.addedByName,
    this.note,
    this.addedAtMs,
    this.votes = const <String, int>{},
  });

  factory FoodMapItemDto.fromJson(Map<String, dynamic> json) =>
      _$FoodMapItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FoodMapItemDtoToJson(this);

  @override
  List<Object?> get props => [
    restaurant,
    addedByUid,
    addedByName,
    note,
    addedAtMs,
    votes,
  ];
}

Map<String, int> _votesFromJson(Object? raw) {
  if (raw is! Map) {
    return const <String, int>{};
  }
  final result = <String, int>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is String && value is num) {
      result[key] = value.toInt();
    }
  }
  return result;
}
