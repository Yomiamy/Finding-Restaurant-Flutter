// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_map_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodMapDto _$FoodMapDtoFromJson(Map<String, dynamic> json) => FoodMapDto(
  title: json['title'] as String?,
  description: json['description'] as String?,
  ownerUid: json['owner_uid'] as String?,
  ownerName: json['owner_name'] as String?,
  inviteCode: json['invite_code'] as String?,
  memberUids: (json['member_uids'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  memberNames: (json['member_names'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  itemCount: (json['item_count'] as num?)?.toInt(),
  createdAtMs: (json['created_at_ms'] as num?)?.toInt(),
  updatedAtMs: (json['updated_at_ms'] as num?)?.toInt(),
);

Map<String, dynamic> _$FoodMapDtoToJson(FoodMapDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'owner_uid': instance.ownerUid,
      'owner_name': instance.ownerName,
      'invite_code': instance.inviteCode,
      'member_uids': instance.memberUids,
      'member_names': instance.memberNames,
      'item_count': instance.itemCount,
      'created_at_ms': instance.createdAtMs,
      'updated_at_ms': instance.updatedAtMs,
    };
