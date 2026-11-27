// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_map_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodMapItemDto _$FoodMapItemDtoFromJson(Map<String, dynamic> json) =>
    FoodMapItemDto(
      restaurant: json['restaurant'] == null
          ? null
          : YelpRestaurantSummaryDto.fromJson(
              json['restaurant'] as Map<String, dynamic>,
            ),
      addedByUid: json['added_by_uid'] as String?,
      addedByName: json['added_by_name'] as String?,
      note: json['note'] as String?,
      addedAtMs: (json['added_at_ms'] as num?)?.toInt(),
      votes: json['votes'] == null
          ? const <String, int>{}
          : _votesFromJson(json['votes']),
    );

Map<String, dynamic> _$FoodMapItemDtoToJson(FoodMapItemDto instance) =>
    <String, dynamic>{
      'restaurant': instance.restaurant?.toJson(),
      'added_by_uid': instance.addedByUid,
      'added_by_name': instance.addedByName,
      'note': instance.note,
      'added_at_ms': instance.addedAtMs,
      'votes': instance.votes,
    };
