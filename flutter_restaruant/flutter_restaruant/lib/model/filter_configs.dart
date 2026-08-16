import 'dart:core';

import 'package:intl/intl.dart';

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
  int? price;
  int get priceIndex => (price == null || price! < 1) ? 0 : (price! - 1);

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
    price = priceIndex + 1;
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

  String getPriceDispStr(int price) {
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
        return 'BestMatch';
      case 'distance':
        return 'Distance';
      case 'review_count':
        return 'ReviewCount';
      case 'rating':
        return 'Rating';
      default:
        return '';
    }
  }
}
