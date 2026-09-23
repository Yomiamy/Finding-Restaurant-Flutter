import 'dart:convert';

import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_test/flutter_test.dart';

/// 驗證 entity 改用 `@JsonSerializable` 後：缺欄位為 null、`toJson` 省略 null key。
void main() {
  group('AllergenInfo / DishItemEntity', () {
    test('缺值 → 欄位為 null（含 List 與 enum）', () {
      final a = AllergenInfo.fromJson(const {});
      expect([a.name, a.riskLevel, a.note], everyElement(isNull));
      final d = DishItemEntity.fromJson(const {});
      expect([
        d.id,
        d.name,
        d.originalName,
        d.price,
        d.category,
        d.allergens,
        d.dietaryTags,
        d.spiceLevel,
        d.ingredients,
        d.chefRecommendationScore,
      ], everyElement(isNull));
    });

    test('toJson 省略 null key，且不含 props/stringify/hashCode', () {
      expect(const AllergenInfo(name: '蛋').toJson(), {'name': '蛋'});
      expect(const DishItemEntity(name: 'A').toJson(), {'name': 'A'});
      expect(jsonEncode(const DishItemEntity().toJson()), '{}');
    });
  });
}
