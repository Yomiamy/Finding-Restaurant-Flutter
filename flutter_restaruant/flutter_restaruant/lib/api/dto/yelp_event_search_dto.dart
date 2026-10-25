import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'yelp_event_dto.dart';

part 'yelp_event_search_dto.g.dart';

@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  explicitToJson: true,
)
class YelpEventSearchDto extends Equatable {
  final List<YelpEventDto>? events;
  final int? total;

  const YelpEventSearchDto({this.events, this.total});

  factory YelpEventSearchDto.fromJson(Map<String, dynamic> json) =>
      _$YelpEventSearchDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpEventSearchDtoToJson(this);

  @override
  List<Object?> get props => [events, total];
}
