import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'yelp_restaurant_location_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class YelpRestaurantLocationDto extends Equatable {
  final String? address1;
  final String? address2;
  final String? address3;
  final String? city;
  final String? country;
  final String? state;
  final List<String>? displayAddress;
  // 新增欄位；省略 null，最愛寫入 Firestore 的 payload 形狀不變。
  @JsonKey(includeIfNull: false)
  final String? zipCode;
  @JsonKey(includeIfNull: false)
  final String? crossStreets;

  const YelpRestaurantLocationDto({
    this.address1,
    this.address2,
    this.address3,
    this.city,
    this.country,
    this.state,
    this.displayAddress,
    this.zipCode,
    this.crossStreets,
  });

  factory YelpRestaurantLocationDto.fromJson(Map<String, dynamic> json) =>
      _$YelpRestaurantLocationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpRestaurantLocationDtoToJson(this);

  @override
  List<Object?> get props => [
    address1,
    address2,
    address3,
    city,
    country,
    state,
    displayAddress,
    zipCode,
    crossStreets,
  ];
}
