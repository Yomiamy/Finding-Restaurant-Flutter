import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:sprintf/sprintf.dart';

import '../../../app/constants/constants_barrel.dart';
import '../../../domain/entities/entities_barrel.dart';
import '../../../domain/repositories/repositories_barrel.dart';
import '../../../features/component/component_barrel.dart';
import '../../../features/component/rating_stars.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../../generated/l10n.dart';
import '../../restaurant/view/restaurant_detail_page.dart';
import 'notes_feed_page.dart';

sealed class _SheetState {
  const _SheetState();
}

final class _SheetUnlinked extends _SheetState {
  const _SheetUnlinked();
}

final class _SheetLoading extends _SheetState {
  const _SheetLoading();
}

final class _SheetLoaded extends _SheetState {
  final RestaurantDetailEntity detail;
  final bool isFavor;

  const _SheetLoaded(this.detail, {this.isFavor = false});
}

final class _SheetFailure extends _SheetState {
  const _SheetFailure();
}

/// 筆記打卡地點標籤點擊後彈出的輕量餐廳摘要 BottomSheet。
class NoteRestaurantSummarySheet extends StatefulWidget {
  static const Duration defaultFavorLookupTimeout = Duration(seconds: 2);
  static final RegExp _validRestaurantIdPattern = RegExp(r'^[A-Za-z0-9_-]+$');

  final UgcNoteEntity note;
  final RestaurantDetailRepository? repository;
  final FavorRepository? favorRepository;
  final void Function(String query)? onOpenMaps;

  const NoteRestaurantSummarySheet({
    super.key,
    required this.note,
    this.repository,
    this.favorRepository,
    this.onOpenMaps,
  });

  /// 檢查 `restaurantId` 是否符合 Yelp Business ID／Alias 允許字元集。
  static bool isValidRestaurantId(String id) =>
      _validRestaurantIdPattern.hasMatch(id);

  static Future<void> show(
    BuildContext context, {
    required UgcNoteEntity note,
    RestaurantDetailRepository? repository,
    FavorRepository? favorRepository,
    void Function(String query)? onOpenMaps,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ThemeSize.space16),
        ),
      ),
      builder: (sheetContext) => NoteRestaurantSummarySheet(
        note: note,
        repository: repository,
        favorRepository: favorRepository,
        onOpenMaps: onOpenMaps,
      ),
    );
  }

  /// 產生傳給 Google Maps 的未編碼查詢字串（有經緯度用座標，否則回退餐廳名稱）。
  static String buildGoogleMapsQuery(
    UgcNoteEntity note,
    RestaurantDetailEntity? detail,
  ) {
    final lat = detail?.coordinates?.latitude;
    final lng = detail?.coordinates?.longitude;
    if (lat != null && lng != null) {
      return sprintf('%f,%f', [lat, lng]);
    }
    final detailName = detail?.name?.trim() ?? '';
    if (detailName.isNotEmpty) {
      return detailName;
    }
    return note.restaurantName.trim();
  }

  /// 將餐廳詳情與筆記保底欄位映射為 [RestaurantEntity]，確保 `id` 非空並帶入收藏狀態。
  static RestaurantEntity toRestaurantEntity(
    UgcNoteEntity note,
    RestaurantDetailEntity detail, {
    bool isFavor = false,
  }) {
    final detailId = detail.id?.trim() ?? '';
    final resolvedId = detailId.isNotEmpty ? detailId : note.restaurantId;
    final detailName = detail.name?.trim() ?? '';
    final resolvedName = detailName.isNotEmpty
        ? detailName
        : note.restaurantName.trim();
    return RestaurantEntity(
      id: resolvedId,
      name: resolvedName,
      imageUrl: detail.imageUrl,
      rating: detail.rating,
      reviewCount: detail.reviewCount,
      price: detail.price,
      phone: detail.phone,
      categories: detail.categories,
      location: detail.location,
      coordinates: detail.coordinates,
      favor: isFavor,
    );
  }

  @override
  State<NoteRestaurantSummarySheet> createState() =>
      _NoteRestaurantSummarySheetState();
}

class _NoteRestaurantSummarySheetState
    extends State<NoteRestaurantSummarySheet> {
  late _SheetState _state;

  @override
  void initState() {
    super.initState();
    if (widget.note.restaurantId.isEmpty) {
      _state = const _SheetUnlinked();
      return;
    }
    if (!NoteRestaurantSummarySheet.isValidRestaurantId(
      widget.note.restaurantId,
    )) {
      Logger().w(
        'Invalid restaurantId rejected before API request: '
        '${widget.note.restaurantId}',
      );
      _state = const _SheetFailure();
      return;
    }
    final repo = _resolveRepository();
    if (repo == null) {
      _state = const _SheetFailure();
      return;
    }
    _state = const _SheetLoading();
    unawaited(_loadDetail(repo));
  }

  RestaurantDetailRepository? _resolveRepository() {
    if (widget.repository != null) {
      return widget.repository;
    }
    if (GetIt.I.isRegistered<RestaurantDetailRepository>()) {
      return GetIt.I<RestaurantDetailRepository>();
    }
    return null;
  }

  FavorRepository? _resolveFavorRepository() {
    if (widget.favorRepository != null) {
      return widget.favorRepository;
    }
    if (GetIt.I.isRegistered<FavorRepository>()) {
      return GetIt.I<FavorRepository>();
    }
    return null;
  }

  Future<bool> _resolveIsFavor(String restaurantId) async {
    final favorRepo = _resolveFavorRepository();
    if (favorRepo == null || restaurantId.isEmpty) {
      return false;
    }
    try {
      return await favorRepo
          .isFavor(restaurantId)
          .timeout(NoteRestaurantSummarySheet.defaultFavorLookupTimeout);
    } on Exception catch (e, st) {
      // Includes TimeoutException when Firestore/legacy migration hangs offline.
      Logger().w(
        'Failed to resolve favorite status for $restaurantId',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  Future<void> _loadDetail(RestaurantDetailRepository repo) async {
    try {
      final detail = await Future.sync(
        () => repo.fetchYelpRestaurantDetailInfo(widget.note.restaurantId),
      );
      if (!mounted) return;
      final detailId = detail.id?.trim() ?? '';
      final hasId = detailId.isNotEmpty;
      final hasName = detail.name?.trim().isNotEmpty ?? false;
      if (!hasId && !hasName) {
        setState(() => _state = const _SheetFailure());
        return;
      }
      final resolvedId = hasId ? detailId : widget.note.restaurantId;
      final isFavor = await _resolveIsFavor(resolvedId);
      if (!mounted) return;
      setState(() => _state = _SheetLoaded(detail, isFavor: isFavor));
    } on Exception catch (e, st) {
      Logger().e(
        'Failed to fetch note restaurant detail',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() => _state = const _SheetFailure());
    }
  }

  void _retryLoad() {
    if (!NoteRestaurantSummarySheet.isValidRestaurantId(
      widget.note.restaurantId,
    )) {
      setState(() => _state = const _SheetFailure());
      return;
    }
    final repo = _resolveRepository();
    if (repo == null) {
      setState(() => _state = const _SheetFailure());
      return;
    }
    setState(() => _state = const _SheetLoading());
    unawaited(_loadDetail(repo));
  }

  void _openMaps(RestaurantDetailEntity? detail) {
    final query = NoteRestaurantSummarySheet.buildGoogleMapsQuery(
      widget.note,
      detail,
    );
    final onOpenMaps = widget.onOpenMaps;
    if (onOpenMaps != null) {
      onOpenMaps(query);
      return;
    }
    Utils.openUrl(
      scheme: Constants.httpsScheme,
      host: Constants.googleMapHost,
      path: Constants.googleMapNavigationPath,
      parameters: <String, String>{Constants.googleMapNavigationLatLng: query},
    );
  }

  void _openRestaurantDetail(
    RestaurantDetailEntity detail, {
    required bool isFavor,
  }) {
    final navigator = Navigator.of(context);
    navigator.pop();
    unawaited(
      navigator.pushNamed(
        RestaurantDetailPage.routeName,
        arguments: Tuple2<RestaurantEntity, dynamic>(
          NoteRestaurantSummarySheet.toRestaurantEntity(
            widget.note,
            detail,
            isFavor: isFavor,
          ),
          null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerTitle = switch (_state) {
      _SheetLoaded(:final detail) =>
        (detail.name?.trim().isNotEmpty ?? false)
            ? (detail.name ?? '').trim()
            : widget.note.restaurantName,
      _SheetUnlinked() ||
      _SheetLoading() ||
      _SheetFailure() => widget.note.restaurantName,
    };

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NoteRestaurantSheetHeader(title: headerTitle),
            Padding(
              padding: const EdgeInsets.all(ThemeSize.space16),
              child: switch (_state) {
                _SheetUnlinked() => _UnlinkedSheetBody(
                  onOpenMaps: () => _openMaps(null),
                ),
                _SheetLoading() => const _LoadingSheetBody(),
                _SheetLoaded(:final detail, :final isFavor) => _LoadedSheetBody(
                  detail: detail,
                  onViewDetail: () =>
                      _openRestaurantDetail(detail, isFavor: isFavor),
                  onOpenMaps: () => _openMaps(detail),
                ),
                _SheetFailure() => _FailureSheetBody(
                  onRetry: _retryLoad,
                  onOpenMaps: () => _openMaps(null),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// BottomSheet 頂部拖曳指示條與餐廳標題列。
class NoteRestaurantSheetHeader extends StatelessWidget {
  final String title;

  const NoteRestaurantSheetHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(top: ThemeSize.space8),
          width: ThemeSize.size48,
          height: ThemeSize.space4,
          decoration: BoxDecoration(
            color: colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(ThemeSize.space4),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ThemeSize.space16,
            ThemeSize.space8,
            ThemeSize.space8,
            ThemeSize.space8,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.place,
                size: ThemeSize.size20,
                color: ThemeColor.colord84a20,
              ),
              const SizedBox(width: ThemeSize.space8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

/// 載入成功時呈現的餐廳縮圖、評分、分類、營業狀態與地址預覽卡片。
class NoteRestaurantDetailPreview extends StatelessWidget {
  final RestaurantDetailEntity detail;

  const NoteRestaurantDetailPreview({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final categoryText = [
      detail.price?.trim() ?? '',
      ...?detail.categories?.map((c) => c.title?.trim() ?? ''),
    ].where((part) => part.isNotEmpty).join(' · ');
    final hours = detail.hours;
    final bool? isOpenNow = (hours != null && hours.isNotEmpty)
        ? hours.first.isOpenNow
        : null;
    final addressText = (detail.location?.displayAddress ?? const <String>[])
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(', ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(ThemeSize.radius8),
              child: SizedBox(
                width: ThemeSize.size80,
                height: ThemeSize.size80,
                child: NoteCoverImage(imageUrl: detail.imageUrl ?? ''),
              ),
            ),
            const SizedBox(width: ThemeSize.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RestaurantRatingRow(
                    rating: detail.rating ?? 0,
                    reviewCount: detail.reviewCount ?? 0,
                  ),
                  if (categoryText.isNotEmpty) ...[
                    const SizedBox(height: ThemeSize.space4),
                    Text(
                      categoryText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (isOpenNow != null) ...[
                    const SizedBox(height: ThemeSize.space5),
                    _OpenStatusBadge(isOpenNow: isOpenNow),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (addressText.isNotEmpty) ...[
          const SizedBox(height: ThemeSize.space12),
          _AddressRow(address: addressText),
        ],
      ],
    );
  }
}

class _RestaurantRatingRow extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const _RestaurantRatingRow({required this.rating, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: ThemeSize.space5,
      runSpacing: ThemeSize.space3,
      children: [
        RatingStars(rating: rating),
        Text(
          rating.toStringAsFixed(1),
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          '$reviewCount${S.current.review_count_suffix}',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _OpenStatusBadge extends StatelessWidget {
  final bool isOpenNow;

  const _OpenStatusBadge({required this.isOpenNow});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isOpenNow ? const Color(0xFF2E7D32) : colorScheme.outline,
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
          isOpenNow
              ? S.current.business_status_open
              : S.current.business_status_closed,
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: ThemeColor.colorffffff,
          ),
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final String address;

  const _AddressRow({required this.address});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on_outlined,
          size: ThemeSize.size16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: ThemeSize.space5),
        Expanded(
          child: Text(
            address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _UnlinkedSheetBody extends StatelessWidget {
  final VoidCallback onOpenMaps;

  const _UnlinkedSheetBody({required this.onOpenMaps});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          S.current.note_restaurant_sheet_unlinked_hint,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: ThemeSize.space16),
        OutlinedButton.icon(
          key: const Key('note_restaurant_sheet_maps_btn'),
          onPressed: onOpenMaps,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, ThemeSize.size48),
          ),
          icon: const Icon(Icons.directions_outlined),
          label: Text(S.current.note_restaurant_sheet_open_maps),
        ),
      ],
    );
  }
}

class _LoadingSheetBody extends StatelessWidget {
  const _LoadingSheetBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: ThemeSize.space20),
      child: Center(child: LoadingWidget()),
    );
  }
}

class _LoadedSheetBody extends StatelessWidget {
  final RestaurantDetailEntity detail;
  final VoidCallback onViewDetail;
  final VoidCallback onOpenMaps;

  const _LoadedSheetBody({
    required this.detail,
    required this.onViewDetail,
    required this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NoteRestaurantDetailPreview(detail: detail),
        const SizedBox(height: ThemeSize.space16),
        FilledButton.icon(
          key: const Key('note_restaurant_sheet_detail_btn'),
          onPressed: onViewDetail,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, ThemeSize.size48),
          ),
          icon: const Icon(Icons.storefront_outlined),
          label: Text(S.current.note_restaurant_sheet_view_detail),
        ),
        const SizedBox(height: ThemeSize.space8),
        OutlinedButton.icon(
          key: const Key('note_restaurant_sheet_maps_btn'),
          onPressed: onOpenMaps,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, ThemeSize.size48),
          ),
          icon: const Icon(Icons.directions_outlined),
          label: Text(S.current.note_restaurant_sheet_open_maps),
        ),
      ],
    );
  }
}

class _FailureSheetBody extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onOpenMaps;

  const _FailureSheetBody({required this.onRetry, required this.onOpenMaps});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.error_outline,
              size: ThemeSize.size20,
              color: colorScheme.error,
            ),
            const SizedBox(width: ThemeSize.space8),
            Expanded(
              child: Text(
                S.current.note_restaurant_sheet_error,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: ThemeSize.space16),
        FilledButton.icon(
          key: const Key('note_restaurant_sheet_retry_btn'),
          onPressed: onRetry,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, ThemeSize.size48),
          ),
          icon: const Icon(Icons.refresh),
          label: Text(S.current.empty_data_retry),
        ),
        const SizedBox(height: ThemeSize.space8),
        OutlinedButton.icon(
          key: const Key('note_restaurant_sheet_maps_btn'),
          onPressed: onOpenMaps,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, ThemeSize.size48),
          ),
          icon: const Icon(Icons.directions_outlined),
          label: Text(S.current.note_restaurant_sheet_open_maps),
        ),
      ],
    );
  }
}
