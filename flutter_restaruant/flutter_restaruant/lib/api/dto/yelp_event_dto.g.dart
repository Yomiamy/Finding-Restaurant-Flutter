// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yelp_event_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YelpEventDto _$YelpEventDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'YelpEventDto',
      json,
      ($checkedConvert) {
        final val = YelpEventDto(
          id: $checkedConvert('id', (v) => v as String?),
          name: $checkedConvert('name', (v) => v as String?),
          description: $checkedConvert('description', (v) => v as String?),
          businessId: $checkedConvert('business_id', (v) => v as String?),
          category: $checkedConvert('category', (v) => v as String?),
          cost: $checkedConvert('cost', (v) => (v as num?)?.toDouble()),
          costMax: $checkedConvert('cost_max', (v) => (v as num?)?.toDouble()),
          eventSiteUrl: $checkedConvert('event_site_url', (v) => v as String?),
          imageUrl: $checkedConvert('image_url', (v) => v as String?),
          ticketsUrl: $checkedConvert('tickets_url', (v) => v as String?),
          timeStart: $checkedConvert('time_start', (v) => v as String?),
          timeEnd: $checkedConvert('time_end', (v) => v as String?),
          attendingCount: $checkedConvert(
            'attending_count',
            (v) => (v as num?)?.toInt(),
          ),
          interestedCount: $checkedConvert(
            'interested_count',
            (v) => (v as num?)?.toInt(),
          ),
          isCanceled: $checkedConvert('is_canceled', (v) => v as bool?),
          isFree: $checkedConvert('is_free', (v) => v as bool?),
          isOfficial: $checkedConvert('is_official', (v) => v as bool?),
          latitude: $checkedConvert('latitude', (v) => (v as num?)?.toDouble()),
          longitude: $checkedConvert(
            'longitude',
            (v) => (v as num?)?.toDouble(),
          ),
          location: $checkedConvert(
            'location',
            (v) => v == null
                ? null
                : YelpRestaurantLocationDto.fromJson(v as Map<String, dynamic>),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'businessId': 'business_id',
        'costMax': 'cost_max',
        'eventSiteUrl': 'event_site_url',
        'imageUrl': 'image_url',
        'ticketsUrl': 'tickets_url',
        'timeStart': 'time_start',
        'timeEnd': 'time_end',
        'attendingCount': 'attending_count',
        'interestedCount': 'interested_count',
        'isCanceled': 'is_canceled',
        'isFree': 'is_free',
        'isOfficial': 'is_official',
      },
    );

Map<String, dynamic> _$YelpEventDtoToJson(YelpEventDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'business_id': instance.businessId,
      'category': instance.category,
      'cost': instance.cost,
      'cost_max': instance.costMax,
      'event_site_url': instance.eventSiteUrl,
      'image_url': instance.imageUrl,
      'tickets_url': instance.ticketsUrl,
      'time_start': instance.timeStart,
      'time_end': instance.timeEnd,
      'attending_count': instance.attendingCount,
      'interested_count': instance.interestedCount,
      'is_canceled': instance.isCanceled,
      'is_free': instance.isFree,
      'is_official': instance.isOfficial,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'location': instance.location?.toJson(),
    };
