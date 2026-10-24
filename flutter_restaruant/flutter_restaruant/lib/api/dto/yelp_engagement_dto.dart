import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'yelp_business_engagement_dto.dart';

part 'yelp_engagement_dto.g.dart';

@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  explicitToJson: true,
)
class YelpEngagementDto extends Equatable {
  final List<YelpBusinessEngagementDto>? data;

  const YelpEngagementDto({this.data});

  factory YelpEngagementDto.fromJson(Map<String, dynamic> json) =>
      _$YelpEngagementDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpEngagementDtoToJson(this);

  @override
  List<Object?> get props => [data];
}
