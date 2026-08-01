import 'package:flutter/widgets.dart';
import '../foundation/style/style_barrel.dart';

class RatingHelper {
  static final Map<String, Image> _ratingImgMap = <String, Image>{
    '0.0': Image.asset('images/Star_rating_0_of_5.png',
        width: Sizes.ratingImageW, height: Sizes.ratingImageH),
    '0.5': Image.asset('images/Star_rating_0.5_of_5.png',
        width: Sizes.ratingImageW, height: Sizes.ratingImageH),
    '1.0': Image.asset('images/Star_rating_1_of_5.png',
        width: Sizes.ratingImageW, height: Sizes.ratingImageH),
    '1.5': Image.asset('images/Star_rating_1.5_of_5.png',
        width: Sizes.ratingImageW, height: Sizes.ratingImageH),
    '2.0': Image.asset('images/Star_rating_2_of_5.png',
        width: Sizes.ratingImageW, height: Sizes.ratingImageH),
    '2.5': Image.asset('images/Star_rating_2.5_of_5.png',
        width: Sizes.ratingImageW, height: Sizes.ratingImageH),
    '3.0': Image.asset('images/Star_rating_3_of_5.png',
        width: Sizes.ratingImageW, height: Sizes.ratingImageH),
    '3.5': Image.asset('images/Star_rating_3.5_of_5.png',
        width: Sizes.ratingImageW, height: Sizes.ratingImageH),
    '4.0': Image.asset('images/Star_rating_4_of_5.png',
        width: Sizes.ratingImageW, height: Sizes.ratingImageH),
    '4.5': Image.asset('images/Star_rating_4.5_of_5.png',
        width: Sizes.ratingImageW, height: Sizes.ratingImageH),
    '5.0': Image.asset('images/Star_rating_5_of_5.png',
        width: Sizes.ratingImageW, height: Sizes.ratingImageH)
  };

  static Widget getRatingImage(String? ratingStr) {
    if (ratingStr == null || ratingStr.isEmpty) {
      return _ratingImgMap['0.0']!;
    }
    int dotIndex = ratingStr.indexOf('.');
    if (dotIndex == -1) {
      ratingStr = '$ratingStr.0';
      dotIndex = ratingStr.indexOf('.');
    }
    String ratingBeforeDotStr = ratingStr.substring(0, dotIndex);
    String ratingAfterDotStr =
        (ratingStr.substring(dotIndex, ratingStr.length).compareTo('.5') < 1)
            ? '.0'
            : '.5';

    String key = '$ratingBeforeDotStr$ratingAfterDotStr';
    return _ratingImgMap[key] ?? _ratingImgMap['0.0']!;
  }
}
