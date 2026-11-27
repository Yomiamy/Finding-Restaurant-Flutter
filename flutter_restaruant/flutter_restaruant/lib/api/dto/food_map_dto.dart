import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'food_map_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class FoodMapDto extends Equatable {
  final String? title;
  final String? description;
  final String? ownerUid;
  final String? ownerName;
  final String? inviteCode;
  final List<String>? memberUids;
  final Map<String, String>? memberNames;
  final int? itemCount;
  final int? createdAtMs;
  final int? updatedAtMs;

  const FoodMapDto({
    this.title,
    this.description,
    this.ownerUid,
    this.ownerName,
    this.inviteCode,
    this.memberUids,
    this.memberNames,
    this.itemCount,
    this.createdAtMs,
    this.updatedAtMs,
  });

  factory FoodMapDto.fromJson(Map<String, dynamic> json) =>
      _$FoodMapDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FoodMapDtoToJson(this);

  @override
  List<Object?> get props => [
    title,
    description,
    ownerUid,
    ownerName,
    inviteCode,
    memberUids,
    memberNames,
    itemCount,
    createdAtMs,
    updatedAtMs,
  ];
}
