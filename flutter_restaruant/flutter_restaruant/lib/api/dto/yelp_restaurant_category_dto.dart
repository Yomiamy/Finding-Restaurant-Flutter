import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'yelp_restaurant_category_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class YelpRestaurantCategoryDto extends Equatable {
  final String? alias;
  final String? title;
  // 只有 /v3/categories 系列會給；省略 null，最愛寫入 Firestore 的 payload 形狀不變。
  @JsonKey(includeIfNull: false)
  final List<String>? parentAliases;
  @JsonKey(includeIfNull: false)
  final List<String>? countryWhitelist;
  @JsonKey(includeIfNull: false)
  final List<String>? countryBlacklist;

  const YelpRestaurantCategoryDto({
    this.alias,
    this.title,
    this.parentAliases,
    this.countryWhitelist,
    this.countryBlacklist,
  });

  factory YelpRestaurantCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$YelpRestaurantCategoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpRestaurantCategoryDtoToJson(this);

  @override
  List<Object?> get props => [
    alias,
    title,
    parentAliases,
    countryWhitelist,
    countryBlacklist,
  ];
}
