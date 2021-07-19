class FilterConfigs {
  int price = 1;
  String get priceDispStr {
    switch (this.price) {
      case 1: return "\$";
      case 2: return "\$\$";
      case 3: return "\$\$\$";
      case 4: return "\$\$\$\$";
      default: return "\$";
    }
  }
  int get priceIndex => this.price - 1;

  int openAt = DateTime.now().millisecondsSinceEpoch;
  DateTime get openAtDateTime => DateTime.fromMillisecondsSinceEpoch(this.openAt);

  String sortBy = "best_match";
  // String get sortingRuleDispStr {
  //   switch(this.sortingRule) {
  //     case "best_match":
  //       return "BestMatch";
  //     case "distance":
  //       return "Distance";
  //     case "review_count":
  //       return "ReviewCount";
  //     case "rating":
  //       return "Rating";
  //     default:
  //       return "BestMatch";
  //   }
  // }
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
}