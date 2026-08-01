import 'package:flutter/material.dart';
import '../../../domain/entities/restaurant_entity.dart';
import '../../../generated/l10n.dart';
import '../../../features/utils/app_utils.dart';
import '../../../features/foundation/style/style.dart';
import '../../../features/foundation/constants/app_constants.dart';
import 'package:sprintf/sprintf.dart';

class RestaurantItemCell extends StatelessWidget {
  static const int imageH = 110;
  static const int imageW = 110;
  static const double itemH = 110;

  final RestaurantEntity _summaryInfo;

  const RestaurantItemCell({super.key, required RestaurantEntity summaryInfo})
      : _summaryInfo = summaryInfo;

  @override
  Widget build(BuildContext context) {
    String category = _summaryInfo.categoriesStr;

    return SizedBox(
        height: itemH,
        child: Container(
            padding: const EdgeInsets.only(
                left: Sizes.space10,
                right: Sizes.space5,
                top: Sizes.space10,
                bottom: Sizes.zero),
            child: Row(mainAxisSize: MainAxisSize.max, children: <Widget>[
              SizedBox(
                  width: RestaurantItemCell.imageW.toDouble(),
                  height: RestaurantItemCell.imageH.toDouble(),
                  child: FadeInImage.assetNetwork(
                      placeholder: UIConstants.noImage,
                      imageErrorBuilder: (context, error, trace) =>
                          Image.asset(UIConstants.noImage),
                      image: _summaryInfo.imageUrl ?? '',
                      imageCacheHeight: RestaurantItemCell.imageH,
                      imageCacheWidth: RestaurantItemCell.imageW,
                      placeholderCacheHeight: RestaurantItemCell.imageH,
                      placeholderCacheWidth: RestaurantItemCell.imageW,
                      fit: BoxFit.fill)),
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.only(left: Sizes.space10),
                      child: SizedBox(
                          height: RestaurantItemCell.itemH,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Flex(
                                    direction: Axis.horizontal,
                                    children: <Widget>[
                                      Expanded(
                                          child: Text(_summaryInfo.name ?? '',
                                              overflow: TextOverflow.ellipsis)),
                                      Text(
                                          sprintf(
                                              '%.2fm', [_summaryInfo.distance]),
                                          style: const TextStyle(
                                              fontSize: UIConstants.mFontSize,
                                              color: Colors.grey))
                                    ]),
                                Flex(
                                    direction: Axis.horizontal,
                                    children: <Widget>[
                                      Expanded(
                                          flex: 1,
                                          child: RatingHelper.getRatingImage(
                                              _summaryInfo.rating?.toString())),
                                      Expanded(
                                          flex: 1,
                                          child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                  '${_summaryInfo.reviewCount ?? 0}${S.current.review_count_suffix}',
                                                  style: const TextStyle(
                                                      fontSize:
                                                          UIConstants.mFontSize,
                                                      color: Colors.grey)))),
                                      Expanded(
                                          flex: 1,
                                          child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                  _summaryInfo.price ?? '',
                                                  style: const TextStyle(
                                                      fontSize:
                                                          UIConstants.mFontSize,
                                                      color: Colors.grey))))
                                    ]),
                                Text(
                                    _summaryInfo.location?.displayAddressStr ??
                                        '',
                                    overflow: TextOverflow.ellipsis),
                                Text(category,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: UIConstants.mFontSize,
                                        color: Colors.grey))
                              ]))))
            ])));
  }
}
