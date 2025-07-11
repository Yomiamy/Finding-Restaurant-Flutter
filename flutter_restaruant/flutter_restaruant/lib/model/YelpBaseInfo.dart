import 'package:flutter/widgets.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import 'package:flutter_restaruant/utils/Utils.dart';
import 'package:json_annotation/json_annotation.dart';

part 'YelpBaseInfo.g.dart';

@JsonSerializable()
class YelpBaseInfo {
  static Map _sRatingImgMap = <String, Image>{
    "0.0": Image.asset("images/Star_rating_0_of_5.png",
        width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "0.5": Image.asset("images/Star_rating_0.5_of_5.png",
        width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "1.0": Image.asset("images/Star_rating_1_of_5.png",
        width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "1.5": Image.asset("images/Star_rating_1.5_of_5.png",
        width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "2.0": Image.asset("images/Star_rating_2_of_5.png",
        width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "2.5": Image.asset("images/Star_rating_1.5_of_5.png",
        width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "3.0": Image.asset("images/Star_rating_3_of_5.png",
        width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "3.5": Image.asset("images/Star_rating_3.5_of_5.png",
        width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "4.0": Image.asset("images/Star_rating_4_of_5.png",
        width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "4.5": Image.asset("images/Star_rating_4.5_of_5.png",
        width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "5.0": Image.asset("images/Star_rating_5_of_5.png",
        width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H)
  };

  YelpBaseInfo();

  Image getRatingImage(String rating) {
    int dotIndex = rating.indexOf(".");
    String ratingBeforeDotStr = rating.substring(0, dotIndex);
    String ratingAfterDotStr =
        (rating.substring(dotIndex, rating.length).compareTo(".5") < 1)
            ? ".0"
            : ".5";

    return _sRatingImgMap["${ratingBeforeDotStr}${ratingAfterDotStr}"];
  }

  String getWeekDayStrByIndex(int day) {
    bool isLocaleZh = Utils.isLocaleZh();

    switch (day) {
      case 0:
        return isLocaleZh ? "星期一" : "Monday";
      case 1:
        return isLocaleZh ? "星期二" : "Tuesday";
      case 2:
        return isLocaleZh ? "星期三" : "Wednesday";
      case 3:
        return isLocaleZh ? "星期四" : "Thursday";
      case 4:
        return isLocaleZh ? "星期五" : "Friday";
      case 5:
        return isLocaleZh ? "星期六" : "Saturday";
      case 6:
        return isLocaleZh ? "星期日" : "Sunday";
    }
    return "";
  }

  bool isNowWeedDayMatchYelpWeekDay(
      {required int nowWeekDay, required int yelpWeekDay}) {
    return (nowWeekDay - 1) == yelpWeekDay;
  }

  String getPriceDispStr(int price) {
    switch (price) {
      case 1:
        return "\$";
      case 2:
        return "\$\$";
      case 3:
        return "\$\$\$";
      case 4:
        return "\$\$\$\$";
      default:
        return "";
    }
  }

  String getSortingRuleDispStr(String sortBy) {
    switch (sortBy) {
      case "best_match":
        return "BestMatch";
      case "distance":
        return "Distance";
      case "review_count":
        return "ReviewCount";
      case "rating":
        return "Rating";
      default:
        return "";
    }
  }

  factory YelpBaseInfo.fromJson(Map<String, dynamic> json) =>
      _$YelpBaseInfoFromJson(json);

  Map<String, dynamic> toJson() => _$YelpBaseInfoToJson(this);
}
