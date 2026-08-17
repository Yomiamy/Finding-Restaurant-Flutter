import 'package:flutter/material.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../../../generated/l10n.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../features/foundation/constants/constants_barrel.dart';
import 'package:sprintf/sprintf.dart';
import '../../rating_stars.dart';

class RestaurantItemCell extends StatelessWidget {
  final RestaurantEntity _summaryInfo;

  const RestaurantItemCell({super.key, required RestaurantEntity summaryInfo})
    : _summaryInfo = summaryInfo;

  @override
  Widget build(BuildContext context) {
    final category = _summaryInfo.categoriesStr;

    return SizedBox(
      height: ThemeSize.image110,
      child: Padding(
        padding: const EdgeInsets.only(
          left: ThemeSize.space10,
          right: ThemeSize.space5,
          top: ThemeSize.space10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: ThemeSize.image110,
              height: ThemeSize.image110,
              child: FadeInImage.assetNetwork(
                placeholder: UIConstants.noImage,
                imageErrorBuilder: (context, error, trace) =>
                    Image.asset(UIConstants.noImage),
                image: _summaryInfo.imageUrl ?? '',
                imageCacheHeight: ThemeSize.image110.toInt(),
                imageCacheWidth: ThemeSize.image110.toInt(),
                placeholderCacheHeight: ThemeSize.image110.toInt(),
                placeholderCacheWidth: ThemeSize.image110.toInt(),
                fit: BoxFit.fill,
              ),
            ),
            const SizedBox(width: ThemeSize.space10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _summaryInfo.name ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        sprintf('%.2fm', [_summaryInfo.distance]),
                        style: const TextStyle(
                          fontSize: UIConstants.mFontSize,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: RatingStars(rating: _summaryInfo.rating ?? 0.0),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_summaryInfo.reviewCount ?? 0}${S.current.review_count_suffix}',
                            style: const TextStyle(
                              fontSize: UIConstants.mFontSize,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _summaryInfo.price ?? '',
                            style: const TextStyle(
                              fontSize: UIConstants.mFontSize,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _summaryInfo.location?.displayAddressStr ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    category,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: UIConstants.mFontSize,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
