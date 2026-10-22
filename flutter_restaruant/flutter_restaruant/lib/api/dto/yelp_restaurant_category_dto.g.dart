// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_restaurant_category_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpRestaurantCategoryDto _$YelpRestaurantCategoryDtoFromJson(
  Map<String, dynamic> json,
) => YelpRestaurantCategoryDto(
  alias: json['alias'] as String?,
  title: json['title'] as String?,
  parentAliases: (json['parent_aliases'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  countryWhitelist: (json['country_whitelist'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  countryBlacklist: (json['country_blacklist'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$YelpRestaurantCategoryDtoToJson(
  YelpRestaurantCategoryDto instance,
) => <String, dynamic>{
  'alias': instance.alias,
  'title': instance.title,
  'parent_aliases': ?instance.parentAliases,
  'country_whitelist': ?instance.countryWhitelist,
  'country_blacklist': ?instance.countryBlacklist,
};
