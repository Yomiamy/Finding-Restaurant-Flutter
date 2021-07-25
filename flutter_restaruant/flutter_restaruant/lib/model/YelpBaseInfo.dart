import 'dart:collection';
import 'package:flutter/widgets.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';
import 'package:json_annotation/json_annotation.dart';

part 'YelpBaseInfo.g.dart';

@JsonSerializable()
class YelpBaseInfo {
  static  Map _sRatingImgMap = <String, Image> {
    "0.0": Image.asset("images/Star_rating_0_of_5.png", width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "0.5": Image.asset("images/Star_rating_0.5_of_5.png", width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "1.0": Image.asset("images/Star_rating_1_of_5.png", width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "1.5": Image.asset("images/Star_rating_1.5_of_5.png", width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "2.0": Image.asset("images/Star_rating_2_of_5.png", width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "2.5": Image.asset("images/Star_rating_1.5_of_5.png", width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "3.0": Image.asset("images/Star_rating_3_of_5.png", width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "3.5": Image.asset("images/Star_rating_3.5_of_5.png", width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "4.0": Image.asset("images/Star_rating_4_of_5.png", width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "4.5": Image.asset("images/Star_rating_4.5_of_5.png", width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H),
    "5.0": Image.asset("images/Star_rating_5_of_5.png", width: UIConstants.RATING_IMAGE_W, height: UIConstants.RATING_IMAGE_H)
  };

  YelpBaseInfo();

  Image getRatingImage(String rating) => YelpBaseInfo._sRatingImgMap[rating];

  String getWeekDayStrByIndex(int day) {
    switch(day) {
      case 0:
        return "星期一";
      case 1:
        return "星期二";
      case 2:
        return "星期三";
      case 3:
        return "星期四";
      case 4:
        return "星期五";
      case 5:
        return "星期六";
      case 6:
        return "星期日";
    }
    return "";
  }

  bool isNowWeedDayMatchYelpWeekDay({required int nowWeekDay, required int yelpWeekDay}) {
    if(nowWeekDay == 1 && yelpWeekDay == 6) return true;
    return (nowWeekDay - 2) == yelpWeekDay;
  }

  String getPriceDispStr(int price) {
    switch (price) {
      case 1: return "\$";
      case 2: return "\$\$";
      case 3: return "\$\$\$";
      case 4: return "\$\$\$\$";
      default: return "";
    }
  }

  String getSortingRuleDispStr(String sortBy) {
    switch(sortBy) {
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
