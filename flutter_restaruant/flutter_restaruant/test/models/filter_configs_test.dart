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
        price: '2',
        categories: 'japanese,taiwanese',
        sortBy: 'best_match',
      );
      expect(configs.categories, 'japanese,taiwanese');
      expect(configs.price, '2');
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

      expect(configs.price, '2');
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
        price: '3',
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

    test('fromUI 在 openNow 為 true 時清除 openAt 並保留 radius', () {
      final targetDate = DateTime(2026, 11, 16, 18, 30);
      final configs = FilterConfigs.fromUI(
        priceIndex: 0,
        openAtDate: targetDate,
        sortingRuleIndex: 0,
        radius: 5000,
        openNow: true,
      );

      expect(configs.openNow, isTrue);
      expect(configs.openAt, isNull);
      expect(configs.radius, 5000);
    });

    test('fromUI 在 openNow 為 false 或 null 時正規化為 null 並保留 openAt', () {
      final targetDate = DateTime(2026, 11, 16, 18, 30);
      final falseConfigs = FilterConfigs.fromUI(
        priceIndex: 0,
        openAtDate: targetDate,
        sortingRuleIndex: 0,
        openNow: false,
      );
      final nullConfigs = FilterConfigs.fromUI(
        priceIndex: 0,
        openAtDate: targetDate,
        sortingRuleIndex: 0,
      );

      expect(falseConfigs.openNow, isNull);
      expect(falseConfigs.openAt, targetDate.millisecondsSinceEpoch);
      expect(nullConfigs.openNow, isNull);
      expect(nullConfigs.openAt, targetDate.millisecondsSinceEpoch);
    });

    test('fromUI 正規化 radius 邊界：保留合法非預設值、過濾 <=0 並上限 clamp 至 40000', () {
      final targetDate = DateTime(2026, 11, 16, 18, 30);
      final validCustom = FilterConfigs.fromUI(
        priceIndex: 0,
        openAtDate: targetDate,
        sortingRuleIndex: 0,
        radius: 2500,
      );
      final zeroRadius = FilterConfigs.fromUI(
        priceIndex: 0,
        openAtDate: targetDate,
        sortingRuleIndex: 0,
        radius: 0,
      );
      final negativeRadius = FilterConfigs.fromUI(
        priceIndex: 0,
        openAtDate: targetDate,
        sortingRuleIndex: 0,
        radius: -100,
      );
      final overMaxRadius = FilterConfigs.fromUI(
        priceIndex: 0,
        openAtDate: targetDate,
        sortingRuleIndex: 0,
        radius: 50000,
      );

      expect(validCustom.radius, 2500);
      expect(zeroRadius.radius, isNull);
      expect(negativeRadius.radius, isNull);
      expect(overMaxRadius.radius, 40000);
    });

    test('clearConfig(radius / openNow) 分別清回 null 且不影響其他欄位', () {
      final configs = FilterConfigs(price: '2', radius: 3000, openNow: true);

      configs.clearConfig(FilterConfigType.radius);
      expect(configs.radius, isNull);
      expect(configs.openNow, isTrue);

      configs.clearConfig(FilterConfigType.openNow);
      expect(configs.openNow, isNull);
      expect(configs.price, '2');
    });
  });
}
