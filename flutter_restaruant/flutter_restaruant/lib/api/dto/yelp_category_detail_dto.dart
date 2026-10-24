import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'yelp_restaurant_category_dto.dart';

part 'yelp_category_detail_dto.g.dart';

@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  explicitToJson: true,
)
class YelpCategoryDetailDto extends Equatable {
  final YelpRestaurantCategoryDto? category;

  const YelpCategoryDetailDto({this.category});

  factory YelpCategoryDetailDto.fromJson(Map<String, dynamic> json) =>
      _$YelpCategoryDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpCategoryDetailDtoToJson(this);

  @override
  List<Object?> get props => [category];
}
