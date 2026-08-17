import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../../../features/foundation/constants/constants_barrel.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../rating_stars.dart';
import 'package:sprintf/sprintf.dart';
import '../../../generated/l10n.dart';
import '../../../features/foundation/style/style_barrel.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantInfoCell extends StatelessWidget {
  static const int _mapImageW = 140;
  static const int _mapImageH = 140;

  final RestaurantDetailEntity _detailInfo;
  final String staticMapUrl;

  const RestaurantInfoCell({
    super.key = const Key('RestaurantImageCell'),
    required RestaurantDetailEntity detailInfo,
    required this.staticMapUrl,
  }) : _detailInfo = detailInfo;

  @override
  Widget build(BuildContext context) {
    String category =
        _detailInfo.categories
            ?.map((category) => category.title ?? '')
            .join(' ') ??
        '';
    bool isOpen = (_detailInfo.hours != null && _detailInfo.hours!.isNotEmpty)
        ? (_detailInfo.hours![0].isOpenNow ?? false)
        : false;
    String openStatus = isOpen ? 'OPEN' : 'CLOSE';

    return Padding(
      padding: const EdgeInsets.only(
        left: ThemeSize.space5,
        right: ThemeSize.space5,
        top: ThemeSize.space10,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          SizedBox(
            width: RestaurantInfoCell._mapImageH.toDouble(),
            height: RestaurantInfoCell._mapImageW.toDouble(),
            child: GestureDetector(
              onTap: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: buildNavigationActionSheet,
                );
              },
              child: FadeInImage.assetNetwork(
                placeholder: UIConstants.noImage,
                imageErrorBuilder: (context, error, trace) =>
                    Image.asset(UIConstants.noImage),
                image: staticMapUrl,
                imageCacheHeight: RestaurantInfoCell._mapImageH,
                imageCacheWidth: RestaurantInfoCell._mapImageW,
                placeholderCacheHeight: RestaurantInfoCell._mapImageH,
                placeholderCacheWidth: RestaurantInfoCell._mapImageW,
                fit: BoxFit.fill,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: ThemeSize.space10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _detailInfo.location?.displayAddressStr ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                        S.current.store_phone,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: ThemeSize.space10),
                      GestureDetector(
                        onTap: () {
                          String phoneStr = _detailInfo.phone ?? '';
                          if (phoneStr.isNotEmpty) {
                            launchUrl(Uri.parse('tel://$phoneStr'));
                          }
                        },
                        child: Text(
                          _detailInfo.phone ?? '',
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    category,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  RatingStars(rating: (_detailInfo.rating ?? 0).toDouble()),
                  Text(
                    '${_detailInfo.reviewCount ?? 0}${S.current.review_count_suffix}',
                    style: const TextStyle(
                      fontSize: UIConstants.mFontSize,
                      color: Colors.grey,
                    ),
                  ),
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.all(
                        Radius.circular(ThemeSize.radiusTag),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(ThemeSize.space3),
                      child: Text(
                        openStatus,
                        style: const TextStyle(
                          fontSize: UIConstants.lFontSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  CupertinoActionSheet buildNavigationActionSheet(
    BuildContext context,
  ) => CupertinoActionSheet(
    title: Text(S.current.navigation_choice),
    cancelButton: CupertinoActionSheetAction(
      isDestructiveAction: true,
      child: Text(S.current.cancel),
      onPressed: () {
        Navigator.pop(context);
      },
    ),
    actions: [
      CupertinoActionSheetAction(
        child: Text(S.current.route_navigation),
        onPressed: () {
          double lat = _detailInfo.coordinates?.latitude ?? 0;
          double lng = _detailInfo.coordinates?.longitude ?? 0;

          Utils.openUrl(
            scheme: Constants.httpsScheme,
            host: Constants.googleMapHost,
            path: Constants.googleMapNavigationPath,
            parameters: <String, String>{
              Constants.googleMapNavigationLatLng: sprintf('%f,%f', [lat, lng]),
            },
          );
          Navigator.pop(context);
        },
      ),
      CupertinoActionSheetAction(
        isDefaultAction: false,
        child: Text(S.current.street_view),
        onPressed: () {
          double lat = _detailInfo.coordinates?.latitude ?? 0;
          double lng = _detailInfo.coordinates?.longitude ?? 0;

          Utils.openUrl(
            scheme: Constants.httpsScheme,
            host: Constants.googleMapHost,
            path: Constants.googleMapNavigationPath,
            parameters: <String, String>{
              Constants.googleMapNavigationLatLng: '',
              Constants.googleMapStreetviewLayer: 'c',
              Constants.googleMapStreetviewLatLng: sprintf('%f,%f', [lat, lng]),
            },
          );
          Navigator.pop(context);
        },
      ),
    ],
  );
}
