// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'a2ui_component.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DishCatalogComponent _$DishCatalogComponentFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DishCatalogComponent', json, ($checkedConvert) {
  final val = DishCatalogComponent(
    restaurantTitle: $checkedConvert('restaurant_title', (v) => v as String?),
    currency: $checkedConvert('currency', (v) => v as String?),
    dishes: $checkedConvert('dishes', (v) => _dishesFromJson(v as List?)),
  );
  return val;
}, fieldKeyMap: const {'restaurantTitle': 'restaurant_title'});

Map<String, dynamic> _$DishCatalogComponentToJson(
  DishCatalogComponent instance,
) => <String, dynamic>{
  'restaurant_title': ?instance.restaurantTitle,
  'currency': ?instance.currency,
  'dishes': ?instance.dishes?.map((e) => e.toJson()).toList(),
};

ComparisonMatrixComponent _$ComparisonMatrixComponentFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ComparisonMatrixComponent', json, ($checkedConvert) {
  final val = ComparisonMatrixComponent(
    title: $checkedConvert('title', (v) => v as String?),
    items: $checkedConvert('items', (v) => _itemsFromJson(v as List?)),
  );
  return val;
});

Map<String, dynamic> _$ComparisonMatrixComponentToJson(
  ComparisonMatrixComponent instance,
) => <String, dynamic>{
  'title': ?instance.title,
  'items': ?instance.items?.map((e) => e.toJson()).toList(),
};

RestaurantComparisonItem _$RestaurantComparisonItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RestaurantComparisonItem', json, ($checkedConvert) {
  final val = RestaurantComparisonItem(
    id: $checkedConvert('id', (v) => v as String?),
    name: $checkedConvert('name', (v) => v as String?),
    rating: $checkedConvert('rating', (v) => (v as num?)?.toDouble()),
    price: $checkedConvert('price', (v) => v as String?),
    highlights: $checkedConvert(
      'highlights',
      (v) => stringListFromJson(v as List?),
    ),
    address: $checkedConvert('address', (v) => v as String?),
    category: $checkedConvert('category', (v) => v as String?),
    imageUrl: $checkedConvert('image_url', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'imageUrl': 'image_url'});

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
) => $checkedCreate('ActionChipGroupComponent', json, ($checkedConvert) {
  final val = ActionChipGroupComponent(
    chips: $checkedConvert('chips', (v) => _chipsFromJson(v as List?)),
  );
  return val;
});

Map<String, dynamic> _$ActionChipGroupComponentToJson(
  ActionChipGroupComponent instance,
) => <String, dynamic>{
  'chips': ?instance.chips?.map((e) => e.toJson()).toList(),
};

ActionChipItem _$ActionChipItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ActionChipItem', json, ($checkedConvert) {
      final val = ActionChipItem(
        label: $checkedConvert('label', (v) => v as String?),
        action: $checkedConvert('action', (v) => v as String?),
        payload: $checkedConvert('payload', (v) => v as Map<String, dynamic>?),
      );
      return val;
    });

Map<String, dynamic> _$ActionChipItemToJson(ActionChipItem instance) =>
    <String, dynamic>{
      'label': ?instance.label,
      'action': ?instance.action,
      'payload': ?instance.payload,
    };

DecisionRouletteComponent _$DecisionRouletteComponentFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DecisionRouletteComponent', json, ($checkedConvert) {
  final val = DecisionRouletteComponent(
    title: $checkedConvert('title', (v) => v as String?),
    options: $checkedConvert('options', (v) => stringListFromJson(v as List?)),
  );
  return val;
});

Map<String, dynamic> _$DecisionRouletteComponentToJson(
  DecisionRouletteComponent instance,
) => <String, dynamic>{'title': ?instance.title, 'options': ?instance.options};

FallbackMarkdownComponent _$FallbackMarkdownComponentFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('FallbackMarkdownComponent', json, ($checkedConvert) {
  final val = FallbackMarkdownComponent(
    text: $checkedConvert('text', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$FallbackMarkdownComponentToJson(
  FallbackMarkdownComponent instance,
) => <String, dynamic>{'text': ?instance.text};
