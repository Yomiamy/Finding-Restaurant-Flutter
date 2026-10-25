import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'yelp_autocomplete_term_dto.dart';
import 'yelp_restaurant_category_dto.dart';
import 'yelp_restaurant_summary_dto.dart';

part 'yelp_autocomplete_dto.g.dart';

/// `/v3/autocomplete` 的回應。
///
/// [businesses] 只會有 `id`、`name`，元素以 id 判斷相等（見 [YelpRestaurantSummaryDto]），
/// 同 id 但其他欄位不同的兩份結果會被視為相等。
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  explicitToJson: true,
)
class YelpAutocompleteDto extends Equatable {
  final List<YelpRestaurantCategoryDto>? categories;
  final List<YelpRestaurantSummaryDto>? businesses;
  final List<YelpAutocompleteTermDto>? terms;

  const YelpAutocompleteDto({this.categories, this.businesses, this.terms});

  factory YelpAutocompleteDto.fromJson(Map<String, dynamic> json) =>
      _$YelpAutocompleteDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpAutocompleteDtoToJson(this);

  @override
  List<Object?> get props => [categories, businesses, terms];
}
