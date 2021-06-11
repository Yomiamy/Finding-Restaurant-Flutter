// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'YelpSearchInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpSearchInfo _$YelpSearchInfoFromJson(Map<String, dynamic> json) {
  return YelpSearchInfo()
    ..businesses = (json['businesses'] as List<dynamic>?)
        ?.map((e) =>
            YelpRestaurantSummaryInfo.fromJson(e as Map<String, dynamic>))
        .toList()
    ..total = json['total'] as int?;
}

Map<String, dynamic> _$YelpSearchInfoToJson(YelpSearchInfo instance) =>
    <String, dynamic>{
      'businesses': instance.businesses,
      'total': instance.total,
    };
