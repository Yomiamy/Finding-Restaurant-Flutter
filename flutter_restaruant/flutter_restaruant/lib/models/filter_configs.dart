import 'dart:core';

import 'package:intl/intl.dart';

import '../generated/l10n.dart';

enum FilterConfigType {
  price,
  openAt,
  sortingRule,
  categories,
  radius,
  openNow,
}

enum SortBy {
  bestMatch('best_match'),
  distance('distance'),
  rating('rating'),
  reviewCount('review_count');

  final String value;
  const SortBy(this.value);

  String toShortString() => value;
}

class FilterConfigs {
  // Yelp Fusion API `/v3/businesses/search` 支援的最大搜尋半徑（公尺）。
  static const int _maxRadiusMeters = 40000;

  // Price
  String? price;
  int get priceIndex {
    if (price == null || price!.isEmpty) return 0;
    final first = int.tryParse(price!.split(',').first.trim());
    return (first == null || first < 1) ? 0 : first - 1;
  }

  // Business hours
  int? openAt;
  DateTime get openAtDateTime => (openAt != null && openAt! > 0)
      ? DateTime.fromMillisecondsSinceEpoch(openAt!)
      : DateTime.now();
  int? get openAtInSec =>
      (openAt != null && openAt! > 0) ? openAt! ~/ 1000 : null;
  String get openAtDispStr => DateFormat('MM-dd HH:mm').format(openAtDateTime);

  // Sorting rule
  String? sortBy;
  int get sortByIndex => (sortBy != null)
      ? SortBy.values
            .firstWhere((element) => element.toShortString() == sortBy)
            .index
      : 0;

  String mapSortingRuleByIndex(int sortByIndex) {
    switch (sortByIndex) {
      case 0:
        return SortBy.bestMatch.toShortString();
      case 1:
        return SortBy.distance.toShortString();
      case 2:
        return SortBy.rating.toShortString();
      case 3:
        return SortBy.reviewCount.toShortString();
      default:
        return SortBy.bestMatch.toShortString();
    }
  }

  // Advanced filters
  String? categories;
  int? radius;
  bool? openNow;

  FilterConfigs({
    this.price,
    this.openAt,
    this.sortBy,
    this.categories,
    this.radius,
    this.openNow,
  });

  FilterConfigs.fromUI({
    required int priceIndex,
    required DateTime openAtDate,
    required int sortingRuleIndex,
    this.categories,
    int? radius,
    bool? openNow,
  }) {
    final isOpenNow = openNow ?? false;
    price = '${priceIndex + 1}';
    this.openNow = isOpenNow ? true : null;
    openAt = isOpenNow ? null : openAtDate.millisecondsSinceEpoch;
    sortBy = mapSortingRuleByIndex(sortingRuleIndex);
    this.radius = _normalizeRadius(radius);
  }

  static int? _normalizeRadius(int? radius) {
    if (radius == null || radius <= 0) {
      return null;
    }
    return radius > _maxRadiusMeters ? _maxRadiusMeters : radius;
  }

  void clearConfig(FilterConfigType configType) {
    switch (configType) {
      case FilterConfigType.price:
        price = null;
        break;
      case FilterConfigType.openAt:
        openAt = null;
        break;
      case FilterConfigType.sortingRule:
        sortBy = null;
        break;
      case FilterConfigType.categories:
        categories = null;
        break;
      case FilterConfigType.radius:
        radius = null;
        break;
      case FilterConfigType.openNow:
        openNow = null;
        break;
    }
  }

  String getPriceDispStr(Object price) {
    if (price is int) {
      return _priceLevelToString(price);
    }
    if (price is String) {
      if (price.contains(',')) {
        return price
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .map(_priceLevelToString)
            .where((s) => s.isNotEmpty)
            .join(', ');
      }
      final p = int.tryParse(price.trim());
      if (p != null) return _priceLevelToString(p);
    }
    return '';
  }

  static String _priceLevelToString(int price) {
    switch (price) {
      case 1:
        return '\$';
      case 2:
        return '\$\$';
      case 3:
        return '\$\$\$';
      case 4:
        return '\$\$\$\$';
      default:
        return '';
    }
  }

  String getSortingRuleDispStr(String sortBy) {
    for (final rule in SortBy.values) {
      if (rule.value == sortBy) {
        return switch (rule) {
          SortBy.bestMatch => S.current.filter_sorting_rule_best_match,
          SortBy.distance => S.current.filter_sorting_rule_distance,
          SortBy.reviewCount => S.current.filter_sorting_review_count,
          SortBy.rating => S.current.filter_sorting_rating,
        };
      }
    }
    return '';
  }
}
