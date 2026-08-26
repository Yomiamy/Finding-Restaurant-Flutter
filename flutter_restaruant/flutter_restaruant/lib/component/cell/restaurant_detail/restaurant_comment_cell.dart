import 'package:flutter/material.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../features/foundation/constants/constants_barrel.dart';
import '../../../generated/l10n.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../rating_stars.dart';

class RestaurantCommentCell extends StatelessWidget {
  static const int _imageSize = 64;

  final List<ReviewDetailEntity> _reviewInfos;
  final ChromeSafariBrowser _browser = ChromeSafariBrowser();

  RestaurantCommentCell({
    super.key = const Key('RestaurantCommentCell'),
    required List<ReviewDetailEntity> reviewInfos,
  }) : _reviewInfos = reviewInfos;

  @override
  Widget build(BuildContext context) {
    if (_reviewInfos.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeSize.space12,
        vertical: ThemeSize.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: ThemeSize.space8),
            child: Row(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: ThemeSize.size18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: ThemeSize.space8),
                Text(
                  S.current.comments,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ..._reviewInfos.map((review) => _buildCommentItem(context, review)),
        ],
      ),
    );
  }

  Widget _buildCommentItem(BuildContext context, ReviewDetailEntity review) {
    final theme = Theme.of(context);
    final headImgUrl = review.user?.imageUrl ?? '';
    final name = review.user?.name ?? '';
    final comment = review.text ?? '';
    final commentUrl = review.url ?? '';
    final double rating = (review.rating ?? 0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: ThemeSize.space12),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(ThemeSize.radius12),
        child: InkWell(
          borderRadius: BorderRadius.circular(ThemeSize.radius12),
          onTap: () {
            if (commentUrl.isNotEmpty) {
              _browser.open(
                url: WebUri(commentUrl),
                settings: ChromeSafariBrowserSettings(
                  barCollapsingEnabled: true,
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(ThemeSize.space12),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(ThemeSize.radius12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(ThemeSize.radius8),
                  child: SizedBox(
                    width: _imageSize.toDouble(),
                    height: _imageSize.toDouble(),
                    child: FadeInImage.assetNetwork(
                      placeholder: UIConstants.noImage,
                      imageErrorBuilder: (context, error, trace) =>
                          Image.asset(UIConstants.noImage, fit: BoxFit.cover),
                      image: headImgUrl,
                      imageCacheHeight: _imageSize,
                      imageCacheWidth: _imageSize,
                      placeholderCacheHeight: _imageSize,
                      placeholderCacheWidth: _imageSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: ThemeSize.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: ThemeSize.space4),
                      RatingStars(rating: rating),
                      const SizedBox(height: ThemeSize.space4),
                      Text(
                        comment,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
