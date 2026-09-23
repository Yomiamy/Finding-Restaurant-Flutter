// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'a2ui_component.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DishCatalogComponent _$DishCatalogComponentFromJson(
  Map<String, dynamic> json,
) => DishCatalogComponent(
  restaurantTitle: json['restaurant_title'] as String?,
  currency: json['currency'] as String?,
  dishes: _dishesFromJson(json['dishes'] as List?),
);

Map<String, dynamic> _$DishCatalogComponentToJson(
  DishCatalogComponent instance,
) => <String, dynamic>{
  'restaurant_title': ?instance.restaurantTitle,
  'currency': ?instance.currency,
  'dishes': ?instance.dishes?.map((e) => e.toJson()).toList(),
};

ComparisonMatrixComponent _$ComparisonMatrixComponentFromJson(
  Map<String, dynamic> json,
) => ComparisonMatrixComponent(
  title: json['title'] as String?,
  items: _itemsFromJson(json['items'] as List?),
);

Map<String, dynamic> _$ComparisonMatrixComponentToJson(
  ComparisonMatrixComponent instance,
) => <String, dynamic>{
  'title': ?instance.title,
  'items': ?instance.items?.map((e) => e.toJson()).toList(),
};

RestaurantComparisonItem _$RestaurantComparisonItemFromJson(
  Map<String, dynamic> json,
) => RestaurantComparisonItem(
  id: json['id'] as String?,
  name: json['name'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
  price: json['price'] as String?,
  highlights: stringListFromJson(json['highlights'] as List?),
  address: json['address'] as String?,
  category: json['category'] as String?,
  imageUrl: json['image_url'] as String?,
);

Map<String, dynamic> _$RestaurantComparisonItemToJson(
  RestaurantComparisonItem instance,
) => <String, dynamic>{
  'id': ?instance.id,
  'name': ?instance.name,
  'rating': ?instance.rating,
  'price': ?instance.price,
  'highlights': ?instance.highlights,
  'address': ?instance.address,
  'category': ?instance.category,
  'image_url': ?instance.imageUrl,
};

ActionChipGroupComponent _$ActionChipGroupComponentFromJson(
  Map<String, dynamic> json,
) => ActionChipGroupComponent(chips: _chipsFromJson(json['chips'] as List?));

Map<String, dynamic> _$ActionChipGroupComponentToJson(
  ActionChipGroupComponent instance,
) => <String, dynamic>{
  'chips': ?instance.chips?.map((e) => e.toJson()).toList(),
};

ActionChipItem _$ActionChipItemFromJson(Map<String, dynamic> json) =>
    ActionChipItem(
      label: json['label'] as String?,
      action: json['action'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ActionChipItemToJson(ActionChipItem instance) =>
    <String, dynamic>{
      'label': ?instance.label,
      'action': ?instance.action,
      'payload': ?instance.payload,
    };

DecisionRouletteComponent _$DecisionRouletteComponentFromJson(
  Map<String, dynamic> json,
) => DecisionRouletteComponent(
  title: json['title'] as String?,
  options: stringListFromJson(json['options'] as List?),
);

Map<String, dynamic> _$DecisionRouletteComponentToJson(
  DecisionRouletteComponent instance,
) => <String, dynamic>{'title': ?instance.title, 'options': ?instance.options};

FallbackMarkdownComponent _$FallbackMarkdownComponentFromJson(
  Map<String, dynamic> json,
) => FallbackMarkdownComponent(text: json['text'] as String?);

Map<String, dynamic> _$FallbackMarkdownComponentToJson(
  FallbackMarkdownComponent instance,
) => <String, dynamic>{'text': ?instance.text};
