import 'dart:core';

import 'package:intl/intl.dart';

import '../generated/l10n.dart';

enum FilterConfigType { price, openAt, sortingRule }

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

  FilterConfigs();

  FilterConfigs.fromUI({
    required int priceIndex,
    required DateTime openAtDate,
    required int sortingRuleIndex,
  }) {
    price = '${priceIndex + 1}';
    openAt = openAtDate.millisecondsSinceEpoch;
    sortBy = mapSortingRuleByIndex(sortingRuleIndex);
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
    switch (sortBy) {
      case 'best_match':
        return S.current.filter_sorting_rule_best_match;
      case 'distance':
        return S.current.filter_sorting_rule_distance;
      case 'review_count':
        return S.current.filter_sorting_review_count;
      case 'rating':
        return S.current.filter_sorting_rating;
      default:
        return '';
    }
  }
}
