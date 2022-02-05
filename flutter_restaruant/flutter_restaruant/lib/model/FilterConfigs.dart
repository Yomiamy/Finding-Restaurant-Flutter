import 'dart:core';
import 'package:flutter_restaruant/model/YelpBaseInfo.dart';
import 'package:intl/intl.dart';

enum FilterConfigType {
  PRICE,
  OPEN_AT,
  SORTING_RULE
}

enum SortBy {
  best_match,
  distance,
  rating,
  review_count
}

extension SortByExtension on SortBy {
  String toShortString() {
    return this.toString().split('.').last;
  }
}

class FilterConfigs extends YelpBaseInfo {
  // Price
  int? price;
  int get priceIndex => (this.price == null || this.price! < 1) ? 0 : (this.price! - 1);

  // Business hours
  int? openAt;
  DateTime get openAtDateTime => (this.openAt != null && this.openAt! > 0) ? DateTime.fromMillisecondsSinceEpoch(this.openAt!) : DateTime.now();
  int? get openAtInSec => (this.openAt != null && this.openAt! > 0) ? openAt! ~/ 1000 : null;
  String get openAtDispStr => DateFormat('MM-dd HH:mm').format(this.openAtDateTime);

  // Sorting rule
  String? sortBy;
  int get sortByIndex => (sortBy != null) ? SortBy.values.firstWhere((element) => element.toShortString() == this.sortBy).index : 0;

  String mapSortingRuleByIndex(int sortByIndex) {
    switch (sortByIndex) {
      case 0:
        return SortBy.best_match.toShortString();
      case 1:
        return SortBy.distance.toShortString();
      case 2:
        return SortBy.rating.toShortString();
      case 3:
        return SortBy.review_count.toShortString();
      default:
        return SortBy.best_match.toShortString();
    }
  }

  FilterConfigs();

  FilterConfigs.fromUI({required int priceIndex, required DateTime openAtDate, required int sortingRuleIndex}) {
    this.price = priceIndex + 1;
    this.openAt = openAtDate.millisecondsSinceEpoch;
    this.sortBy = this.mapSortingRuleByIndex(sortingRuleIndex);
  }

  void clearConfig(FilterConfigType configType) {
    switch(configType) {
      case FilterConfigType.PRICE:
        this.price = null;
        break;
      case FilterConfigType.OPEN_AT:
        this.openAt = null;
        break;
      case FilterConfigType.SORTING_RULE:
        this.sortBy = null;
        break;
    }
  }
}