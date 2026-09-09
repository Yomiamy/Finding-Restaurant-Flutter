import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'dish_item_entity.dart';

/// GenUI (A2UI) 宣告式元件協定基類
///
/// 使用 Dart 3 sealed class，編譯期強制窮盡檢查所有元件子型別。
@immutable
sealed class A2UIComponent extends Equatable {
  const A2UIComponent();

  factory A2UIComponent.fromJson(Map<String, Object?> json) {
    final componentType = json['component_type'] as String? ?? '';
    final data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};

    return switch (componentType) {
      'dish_catalog' => DishCatalogComponent.fromJson(data),
      _ => FallbackMarkdownComponent(
        text: (json['text'] as String?) ?? '無法識別的 GenUI 元件結構',
      ),
    };
  }

  Map<String, Object?> toJson();
}

/// 互動式菜單看板元件 (Dish Catalog Component)
final class DishCatalogComponent extends A2UIComponent {
  const DishCatalogComponent({
    required this.dishes,
    this.restaurantTitle,
    this.currency = 'TWD',
  });

  factory DishCatalogComponent.fromJson(Map<String, Object?> json) {
    final rawDishes = json['dishes'] as List<Object?>? ?? const [];
    final dishes = rawDishes
        .whereType<Map<String, Object?>>()
        .map(DishItemEntity.fromJson)
        .toList(growable: false);

    return DishCatalogComponent(
      restaurantTitle: json['restaurant_title'] as String?,
      currency: json['currency'] as String? ?? 'TWD',
      dishes: dishes,
    );
  }

  final String? restaurantTitle;
  final String currency;
  final List<DishItemEntity> dishes;

  @override
  Map<String, Object?> toJson() => {
    'component_type': 'dish_catalog',
    'data': {
      if (restaurantTitle != null) 'restaurant_title': restaurantTitle,
      'currency': currency,
      'dishes': dishes.map((d) => d.toJson()).toList(growable: false),
    },
  };

  @override
  List<Object?> get props => [restaurantTitle, currency, dishes];
}

/// 安全降級文字卡片 (Fallback Markdown Component)
///
/// 當模型輸出結構異常、部分破損或非預期元件時安全降級，保證絕不崩潰。
final class FallbackMarkdownComponent extends A2UIComponent {
  const FallbackMarkdownComponent({required this.text});

  final String text;

  @override
  Map<String, Object?> toJson() => {
    'component_type': 'fallback_markdown',
    'text': text,
  };

  @override
  List<Object?> get props => [text];
}
