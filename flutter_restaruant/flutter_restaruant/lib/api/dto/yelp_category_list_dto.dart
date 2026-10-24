import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'yelp_restaurant_category_dto.dart';

part 'yelp_category_list_dto.g.dart';

@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  explicitToJson: true,
)
class YelpCategoryListDto extends Equatable {
  final List<YelpRestaurantCategoryDto>? categories;

  const YelpCategoryListDto({this.categories});

  factory YelpCategoryListDto.fromJson(Map<String, dynamic> json) =>
      _$YelpCategoryListDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpCategoryListDtoToJson(this);

  @override
  List<Object?> get props => [categories];
}
