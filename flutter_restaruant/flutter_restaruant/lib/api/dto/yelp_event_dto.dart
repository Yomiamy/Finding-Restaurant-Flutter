import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'yelp_restaurant_location_dto.dart';

part 'yelp_event_dto.g.dart';

@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  explicitToJson: true,
)
class YelpEventDto extends Equatable {
  final String? id;
  final String? name;
  final String? description;
  final String? businessId;
  final String? category;
  final double? cost;
  final double? costMax;
  final String? eventSiteUrl;
  final String? imageUrl;
  final String? ticketsUrl;
  final String? timeStart;
  final String? timeEnd;
  final int? attendingCount;
  final int? interestedCount;
  final bool? isCanceled;
  final bool? isFree;
  final bool? isOfficial;
  final double? latitude;
  final double? longitude;
  final YelpRestaurantLocationDto? location;

  const YelpEventDto({
    this.id,
    this.name,
    this.description,
    this.businessId,
    this.category,
    this.cost,
    this.costMax,
    this.eventSiteUrl,
    this.imageUrl,
    this.ticketsUrl,
    this.timeStart,
    this.timeEnd,
    this.attendingCount,
    this.interestedCount,
    this.isCanceled,
    this.isFree,
    this.isOfficial,
    this.latitude,
    this.longitude,
    this.location,
  });

  factory YelpEventDto.fromJson(Map<String, dynamic> json) =>
      _$YelpEventDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpEventDtoToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    businessId,
    category,
    cost,
    costMax,
    eventSiteUrl,
    imageUrl,
    ticketsUrl,
    timeStart,
    timeEnd,
    attendingCount,
    interestedCount,
    isCanceled,
    isFree,
    isOfficial,
    latitude,
    longitude,
    location,
  ];
}
