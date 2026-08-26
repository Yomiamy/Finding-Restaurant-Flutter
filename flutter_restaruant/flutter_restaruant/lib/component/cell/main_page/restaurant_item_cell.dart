import 'package:flutter/material.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../features/foundation/constants/constants_barrel.dart';
import '../../../features/foundation/extension/extension_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';
import '../../rating_stars.dart';

/// 餐廳列表與地圖卡片中的項目單元 (Restaurant Item Cell)。
class RestaurantItemCell extends StatelessWidget {
  final RestaurantEntity _summaryInfo;

  const RestaurantItemCell({super.key, required RestaurantEntity summaryInfo})
    : _summaryInfo = summaryInfo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final category =
        _summaryInfo.categories
            ?.map((c) => c.title)
            .where((t) => t != null && t.isNotEmpty)
            .join(' · ') ??
        _summaryInfo.categoriesStr;

    return Padding(
      padding: const EdgeInsets.only(
        left: ThemeSize.space10,
        right: ThemeSize.space5,
        top: ThemeSize.space10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.all(
              Radius.circular(ThemeSize.radius8),
            ),
            child: FadeInImage.assetNetwork(
              width: ThemeSize.size110,
              height: ThemeSize.size110,
              placeholder: UIConstants.noImage,
              // FadeInImage 的 width/height 不會傳給 errorBuilder 回傳的 widget，
              // 這裡必須自行約束，否則載圖失敗時會用原圖尺寸撐爆外層 Row。
              imageErrorBuilder: (context, error, trace) => Image.asset(
                UIConstants.noImage,
                width: ThemeSize.size110,
                height: ThemeSize.size110,
                fit: BoxFit.cover,
              ),
              image: _summaryInfo.imageUrl ?? '',
              imageCacheHeight: ThemeSize.size110.toInt(),
              imageCacheWidth: ThemeSize.size110.toInt(),
              placeholderCacheHeight: ThemeSize.size110.toInt(),
              placeholderCacheWidth: ThemeSize.size110.toInt(),
              fit: BoxFit.cover,
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
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: ThemeSize.space5),
                    Text(
                      _summaryInfo.distance.formatDistance(),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    // RatingStars 是 5 個固定 16px Icon，寬度不可壓縮，
                    // 因此不參與 flex 分配；剩餘空間全交給可 ellipsis 的文字。
                    // 包成 Expanded 會在窄卡片（地圖 viewportFraction 0.85）下溢出。
                    RatingStars(rating: _summaryInfo.rating ?? 0.0),
                    const SizedBox(width: ThemeSize.space5),
                    Expanded(
                      child: Text(
                        '${_summaryInfo.reviewCount ?? 0}${S.current.review_count_suffix}',
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ),
                    const SizedBox(width: ThemeSize.space5),
                    Expanded(
                      child: Text(
                        _summaryInfo.price ?? '',
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _summaryInfo.location?.displayAddressStr ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  category,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
