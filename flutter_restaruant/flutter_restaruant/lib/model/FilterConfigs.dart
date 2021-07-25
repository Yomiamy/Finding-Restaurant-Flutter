import 'package:flutter_restaruant/model/YelpBaseInfo.dart';
import 'package:intl/intl.dart';

enum FilterConfigType {
  PRICE,
  OPEN_AT,
  SORTING_RULE
}

class FilterConfigs extends YelpBaseInfo {
  // Price
  int? price = 1;
  int get priceIndex => (this.price == null || this.price! < 1) ? 0 : (this.price! - 1);

  // Business hours
  int? openAt = DateTime.now().millisecondsSinceEpoch;
  DateTime get openAtDateTime => (this.openAt != null && this.openAt! > 0) ? DateTime.fromMillisecondsSinceEpoch(this.openAt!) : DateTime.now();
  String get openAtDispStr => DateFormat('MM-dd HH:mm').format(this.openAtDateTime);

  // Sorting rule
  String? sortBy = "best_match";
  int get sortByIndex {
    switch(this.sortBy) {
      case "best_match":
        return 0;
      case "distance":
        return 1;
      case "rating":
        return 2;
      case "review_count":
        return 3;
      default:
        return 0;
    }
  }
  String mapSortingRuleByIndex(int sortByIndex) {
    switch (sortByIndex) {
      case 0:
        return "best_match";
      case 1:
        return "distance";
      case 2:
        return "rating";
      case 3:
        return "review_count";
      default:
        return "best_match";
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