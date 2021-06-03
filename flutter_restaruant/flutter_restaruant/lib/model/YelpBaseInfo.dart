import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:flutter_restaruant/utils/UIConstants.dart';

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

  Image getRatingImage(String rating) => YelpBaseInfo._sRatingImgMap[rating];
}
