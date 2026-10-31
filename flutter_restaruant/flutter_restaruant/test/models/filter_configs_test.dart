import 'package:flutter_restaruant/models/filter_configs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FilterConfigs Tests', () {
    test('預設值 categories 為 null', () {
      final configs = FilterConfigs();
      expect(configs.categories, isNull);
      expect(configs.price, isNull);
      expect(configs.openAt, isNull);
      expect(configs.sortBy, isNull);
    });

    test('具名建構子正確賦值 categories', () {
      final configs = FilterConfigs(
        price: 2,
        categories: 'japanese,taiwanese',
        sortBy: 'best_match',
      );
      expect(configs.categories, 'japanese,taiwanese');
      expect(configs.price, 2);
      expect(configs.sortBy, 'best_match');
    });

    test('fromUI 建構子正確設定 categories', () {
      final now = DateTime.now();
      final configs = FilterConfigs.fromUI(
        priceIndex: 1,
        openAtDate: now,
        sortingRuleIndex: 2,
        categories: 'hotpot',
      );

      expect(configs.price, 2);
      expect(configs.priceIndex, 1);
      expect(configs.categories, 'hotpot');
      expect(configs.sortBy, 'rating');
    });

    test('clearConfig(FilterConfigType.categories) 清除 categories', () {
      final configs = FilterConfigs(categories: 'korean');
      expect(configs.categories, 'korean');

      configs.clearConfig(FilterConfigType.categories);
      expect(configs.categories, isNull);
    });

    test('clearConfig 對其他欄位運作正常', () {
      final configs = FilterConfigs(
        price: 3,
        openAt: 1234567,
        sortBy: 'distance',
        categories: 'cafes',
      );

      configs.clearConfig(FilterConfigType.price);
      expect(configs.price, isNull);
      expect(configs.categories, 'cafes');

      configs.clearConfig(FilterConfigType.openAt);
      expect(configs.openAt, isNull);

      configs.clearConfig(FilterConfigType.sortingRule);
      expect(configs.sortBy, isNull);
      expect(configs.categories, 'cafes');
    });
  });
}
