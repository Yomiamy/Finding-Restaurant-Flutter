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
      'dish_catalog' => () {
          final comp = DishCatalogComponent.fromJson(data);
          if (comp.dishes.isEmpty) {
            return FallbackMarkdownComponent(
              text: (json['text'] as String?) ?? comp.restaurantTitle ?? '菜單資料為空',
            );
          }
          return comp;
        }(),
      'comparison_matrix' => () {
          final comp = ComparisonMatrixComponent.fromJson(data);
          if (comp.items.isEmpty) {
            return FallbackMarkdownComponent(
              text: (json['text'] as String?) ?? comp.title,
            );
          }
          return comp;
        }(),
      'action_chip_group' => () {
          final comp = ActionChipGroupComponent.fromJson(data);
          if (comp.chips.isEmpty) {
            return FallbackMarkdownComponent(
              text: (json['text'] as String?) ?? '快捷操作選項',
            );
          }
          return comp;
        }(),
      'decision_roulette' => () {
          final comp = DecisionRouletteComponent.fromJson(data);
          if (comp.options.length < 2) {
            return FallbackMarkdownComponent(
              text: (json['text'] as String?) ?? comp.title,
            );
          }
          return comp;
        }(),
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

/// 多店對比矩陣元件 (Comparison Matrix Component)
final class ComparisonMatrixComponent extends A2UIComponent {
  const ComparisonMatrixComponent({
    required this.title,
    required this.items,
  });

  factory ComparisonMatrixComponent.fromJson(Map<String, Object?> json) {
    final title = json['title'] as String? ?? '推薦餐廳對比';
    final rawItems = json['items'] as List<Object?>? ?? const [];
    final items = rawItems
        .whereType<Map<String, Object?>>()
        .map(RestaurantComparisonItem.fromJson)
        .toList(growable: false);

    return ComparisonMatrixComponent(title: title, items: items);
  }

  final String title;
  final List<RestaurantComparisonItem> items;

  @override
  Map<String, Object?> toJson() => {
    'component_type': 'comparison_matrix',
    'data': {
      'title': title,
      'items': items.map((e) => e.toJson()).toList(growable: false),
    },
  };

  @override
  List<Object?> get props => [title, items];
}

/// 餐廳對比卡片項目
final class RestaurantComparisonItem extends Equatable {
  const RestaurantComparisonItem({
    required this.id,
    required this.name,
    required this.rating,
    this.price,
    this.highlights = const [],
    this.address,
    this.category,
    this.imageUrl,
  });

  factory RestaurantComparisonItem.fromJson(Map<String, Object?> json) {
    final rawHighlights = json['highlights'] as List<Object?>? ?? const [];
    final highlights = rawHighlights
        .whereType<String>()
        .toList(growable: false);

    return RestaurantComparisonItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '精選餐廳',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      price: json['price'] as String?,
      highlights: highlights,
      address: json['address'] as String?,
      category: json['category'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  final String id;
  final String name;
  final double rating;
  final String? price;
  final List<String> highlights;
  final String? address;
  final String? category;
  final String? imageUrl;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'rating': rating,
    if (price != null) 'price': price,
    'highlights': highlights,
    if (address != null) 'address': address,
    if (category != null) 'category': category,
    if (imageUrl != null) 'image_url': imageUrl,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    rating,
    price,
    highlights,
    address,
    category,
    imageUrl,
  ];
}

/// 行動標籤群組元件 (Action Chip Group Component)
final class ActionChipGroupComponent extends A2UIComponent {
  const ActionChipGroupComponent({required this.chips});

  factory ActionChipGroupComponent.fromJson(Map<String, Object?> json) {
    final rawChips = json['chips'] as List<Object?>? ?? const [];
    final chips = rawChips
        .whereType<Map<String, Object?>>()
        .map(ActionChipItem.fromJson)
        .where((c) => c.isValid)
        .toList(growable: false);
 
    return ActionChipGroupComponent(chips: chips);
  }

  final List<ActionChipItem> chips;

  @override
  Map<String, Object?> toJson() => {
    'component_type': 'action_chip_group',
    'data': {
      'chips': chips.map((c) => c.toJson()).toList(growable: false),
    },
  };

  @override
  List<Object?> get props => [chips];
}

/// 行動標籤項目
final class ActionChipItem extends Equatable {
  const ActionChipItem({
    required this.label,
    required this.action,
    this.payload = const {},
  });

  factory ActionChipItem.fromJson(Map<String, Object?> json) {
    return ActionChipItem(
      label: json['label'] as String? ?? '',
      action: json['action'] as String? ?? '',
      payload: (json['payload'] as Map<String, Object?>?) ?? const {},
    );
  }

  final String label;
  final String action;
  final Map<String, Object?> payload;

  /// 檢查此行動標籤是否具備合法的必要欄位與載荷
  bool get isValid {
    if (label.trim().isEmpty || action.trim().isEmpty) return false;
    return switch (action) {
      'query' => (payload['prompt'] as String?)?.trim().isNotEmpty ?? false,
      'open_roulette' => () {
        final options = payload['options'] as List<Object?>?;
        return options != null &&
            options
                .whereType<String>()
                .where((s) => s.trim().isNotEmpty)
                .length >= 2;
      }(),
      _ => true, // 保留對未知或未來自訂動作的向後相容性
    };
  }

  Map<String, Object?> toJson() => {
    'label': label,
    'action': action,
    'payload': payload,
  };

  @override
  List<Object?> get props => [label, action, payload];
}

/// 命運轉盤元件 (Decision Roulette Component)
final class DecisionRouletteComponent extends A2UIComponent {
  const DecisionRouletteComponent({
    required this.options,
    this.title = '今晚吃什麼？命運大轉盤',
  });

  factory DecisionRouletteComponent.fromJson(Map<String, Object?> json) {
    final rawOptions = json['options'] as List<Object?>? ?? const [];
    final options = rawOptions
        .whereType<String>()
        .toList(growable: false);

    return DecisionRouletteComponent(
      title: json['title'] as String? ?? '今晚吃什麼？命運大轉盤',
      options: options,
    );
  }

  final String title;
  final List<String> options;

  @override
  Map<String, Object?> toJson() => {
    'component_type': 'decision_roulette',
    'data': {
      'title': title,
      'options': options,
    },
  };

  @override
  List<Object?> get props => [title, options];
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
