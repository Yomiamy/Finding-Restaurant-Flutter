import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../domain/entities/entities_barrel.dart';
import '../../../../app/constants/constants_barrel.dart';
import '../../../../gen/assets.gen.dart';
import '../../../foundation/style/style_barrel.dart';
import '../../../utils/utils_barrel.dart';
import '../../../../generated/l10n.dart';
import '../../rating_stars.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String phone = _detailInfo.phone ?? '';
    final String displayPhone = _detailInfo.displayPhone ?? '';
    final String url = _detailInfo.url ?? '';
    // 價位放最前面：分類列 maxLines 為 1，尾端的分類會先被截掉。
    final String category = [
      _detailInfo.price ?? '',
      ...?_detailInfo.categories?.map((category) => category.title ?? ''),
    ].where((part) => part.isNotEmpty).join(' · ');
    final bool isOpen =
        (_detailInfo.hours != null && _detailInfo.hours!.isNotEmpty)
        ? (_detailInfo.hours![0].isOpenNow ?? false)
        : false;
    final String openStatus = isOpen
        ? S.current.business_status_open
        : S.current.business_status_closed;
    final Color openStatusColor = isOpen
        ? const Color(0xFF2E7D32)
        : colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeSize.space12,
        vertical: ThemeSize.space10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: RestaurantInfoCell._mapImageW.toDouble(),
            height: RestaurantInfoCell._mapImageH.toDouble(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ThemeSize.radius8),
              child: GestureDetector(
                onTap: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: buildNavigationActionSheet,
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FadeInImage.assetNetwork(
                      placeholder: Assets.images.iconStaticMapPlachold.path,
                      imageErrorBuilder: (context, error, trace) =>
                          Assets.images.iconStaticMapPlachold.image(
                            fit: BoxFit.cover,
                          ),
                      image: staticMapUrl,
                      imageCacheHeight: RestaurantInfoCell._mapImageH,
                      imageCacheWidth: RestaurantInfoCell._mapImageW,
                      placeholderCacheHeight: RestaurantInfoCell._mapImageH,
                      placeholderCacheWidth: RestaurantInfoCell._mapImageW,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: ThemeSize.space5,
                      right: ThemeSize.space5,
                      child: Container(
                        padding: const EdgeInsets.all(ThemeSize.space4),
                        decoration: BoxDecoration(
                          color: ThemeColor.color8a000000,
                          borderRadius: BorderRadius.circular(
                            ThemeSize.radius8,
                          ),
                        ),
                        child: const Icon(
                          Icons.navigation_rounded,
                          size: ThemeSize.size16,
                          color: ThemeColor.colorffffff,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: ThemeSize.space12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          _detailInfo.location?.displayAddressStr ?? '',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (url.isNotEmpty)
                        IconButton(
                          tooltip: S.current.open_in_yelp,
                          // 高度對齊地址單行行高（20），不撐高標題列；點擊區刻意小於 48dp。
                          padding: const EdgeInsets.symmetric(
                            horizontal: ThemeSize.space4,
                          ),
                          constraints: const BoxConstraints(
                            minHeight: ThemeSize.size20,
                          ),
                          style: const ButtonStyle(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(
                            Icons.open_in_new,
                            size: ThemeSize.size16,
                            color: colorScheme.primary,
                          ),
                          onPressed: () => Utils.openUrl(rawUrl: url),
                        ),
                    ],
                  ),
                  const SizedBox(height: ThemeSize.space4),
                  if (phone.isNotEmpty)
                    _InfoLinkRow(
                      icon: Icons.phone_outlined,
                      // 撥號一律用 phone；displayPhone 含空白與括號，只負責顯示。
                      label: displayPhone.isEmpty ? phone : displayPhone,
                      onTap: () => launchUrl(Uri.parse('tel://$phone')),
                    ),
                  if (category.isNotEmpty) ...[
                    const SizedBox(height: ThemeSize.space3),
                    Text(
                      category,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: ThemeFontSize.fontSize12,
                      ),
                    ),
                  ],
                  const SizedBox(height: ThemeSize.space4),
                  Row(
                    children: [
                      RatingStars(rating: (_detailInfo.rating ?? 0).toDouble()),
                      const SizedBox(width: ThemeSize.space5),
                      Text(
                        '${_detailInfo.reviewCount ?? 0}${S.current.review_count_suffix}',
                        style: TextStyle(
                          fontSize: ThemeFontSize.fontSize12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ThemeSize.space5),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: openStatusColor,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(ThemeSize.radiusTag),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ThemeSize.space8,
                        vertical: ThemeSize.space3,
                      ),
                      child: Text(
                        openStatus,
                        style: const TextStyle(
                          fontSize: ThemeFontSize.fontSize12,
                          fontWeight: FontWeight.bold,
                          color: ThemeColor.colorffffff,
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

class _InfoLinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _InfoLinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ThemeSize.radius8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ThemeSize.space3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: ThemeSize.size16, color: colorScheme.primary),
            const SizedBox(width: ThemeSize.space5),
            // 窄螢幕下較長的 displayPhone 改為換行，避免 Row 溢出。
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: ThemeFontSize.fontSize14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
