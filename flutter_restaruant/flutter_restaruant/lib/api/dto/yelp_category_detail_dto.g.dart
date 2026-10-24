// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_category_detail_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpCategoryDetailDto _$YelpCategoryDetailDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('YelpCategoryDetailDto', json, ($checkedConvert) {
  final val = YelpCategoryDetailDto(
    category: $checkedConvert(
      'category',
      (v) => v == null
          ? null
          : YelpRestaurantCategoryDto.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$YelpCategoryDetailDtoToJson(
  YelpCategoryDetailDto instance,
) => <String, dynamic>{'category': instance.category?.toJson()};
