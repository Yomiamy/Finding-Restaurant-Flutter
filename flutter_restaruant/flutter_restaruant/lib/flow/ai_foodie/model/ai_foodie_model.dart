import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities_barrel.dart';

/// AI 覓食對話訊息 UI model（欄位 non-null，預設值集中於 [fromEntity]）
class AiFoodieMessageModel extends Equatable {
  const AiFoodieMessageModel({
    required this.isUser,
    required this.text,
    required this.components,
  });

  factory AiFoodieMessageModel.fromEntity(AiFoodieMessage entity) {
    return AiFoodieMessageModel(
      isUser: entity.isUser,
      text: entity.text,
      components: entity.components
          .map(A2UIComponentModel.fromEntity)
          .nonNulls
          .toList(growable: false),
    );
  }

  final bool isUser;
  final String text;
  final List<A2UIComponentModel> components;

  @override
  List<Object?> get props => [isUser, text, components];
}

/// GenUI (A2UI) 元件 UI model 基類，View 依此做窮盡式 switch
sealed class A2UIComponentModel extends Equatable {
  const A2UIComponentModel();

  /// `DishCatalogComponent` 在 AI 覓食畫布不渲染，回傳 null 由呼叫端 `.nonNulls` 略過。
  static A2UIComponentModel? fromEntity(A2UIComponent entity) {
    return switch (entity) {
      ComparisonMatrixComponent() => ComparisonMatrixModel.fromEntity(entity),
      ActionChipGroupComponent() => ActionChipGroupModel.fromEntity(entity),
      DecisionRouletteComponent() => DecisionRouletteModel.fromEntity(entity),
      FallbackMarkdownComponent() => FallbackTextModel(text: entity.text),
      DishCatalogComponent() => null,
    };
  }
}

/// 多店對比矩陣 UI model
final class ComparisonMatrixModel extends A2UIComponentModel {
  const ComparisonMatrixModel({required this.title, required this.items});

  factory ComparisonMatrixModel.fromEntity(ComparisonMatrixComponent entity) {
    return ComparisonMatrixModel(
      title: entity.title,
      items: entity.items
          .map(ComparisonItemModel.fromEntity)
          .toList(growable: false),
    );
  }

  final String title;
  final List<ComparisonItemModel> items;

  @override
  List<Object?> get props => [title, items];
}

/// 行動標籤群組 UI model
final class ActionChipGroupModel extends A2UIComponentModel {
  const ActionChipGroupModel({required this.chips});

  factory ActionChipGroupModel.fromEntity(ActionChipGroupComponent entity) {
    return ActionChipGroupModel(
      chips: entity.chips
          .map(ActionChipModel.fromEntity)
          .toList(growable: false),
    );
  }

  final List<ActionChipModel> chips;

  @override
  List<Object?> get props => [chips];
}

/// 命運轉盤 UI model
final class DecisionRouletteModel extends A2UIComponentModel {
  const DecisionRouletteModel({required this.title, required this.options});

  factory DecisionRouletteModel.fromEntity(DecisionRouletteComponent entity) {
    return DecisionRouletteModel(title: entity.title, options: entity.options);
  }

  final String title;
  final List<String> options;

  @override
  List<Object?> get props => [title, options];
}

/// 安全降級文字 UI model
final class FallbackTextModel extends A2UIComponentModel {
  const FallbackTextModel({required this.text});

  final String text;

  @override
  List<Object?> get props => [text];
}

/// 餐廳對比卡片項目 UI model
///
/// `price`／`address`／`category`／`imageUrl` 刻意維持 `String?`：現行預設就是 `null`，
/// View 以 `!= null` 決定是否渲染，改成 `''` 會讓畫面出現額外間距。
class ComparisonItemModel extends Equatable {
  const ComparisonItemModel({
    required this.id,
    required this.name,
    required this.rating,
    this.price,
    required this.highlights,
    this.address,
    this.category,
    this.imageUrl,
  });

  factory ComparisonItemModel.fromEntity(RestaurantComparisonItem entity) {
    return ComparisonItemModel(
      id: entity.id,
      name: entity.name,
      rating: entity.rating,
      price: entity.price,
      highlights: entity.highlights,
      address: entity.address,
      category: entity.category,
      imageUrl: entity.imageUrl,
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

/// 行動標籤 UI model
class ActionChipModel extends Equatable {
  const ActionChipModel({
    required this.label,
    required this.action,
    required this.payload,
  });

  factory ActionChipModel.fromEntity(ActionChipItem entity) {
    return ActionChipModel(
      label: entity.label,
      action: entity.action,
      payload: entity.payload,
    );
  }

  final String label;
  final String action;
  final Map<String, Object?> payload;

  @override
  List<Object?> get props => [label, action, payload];
}
