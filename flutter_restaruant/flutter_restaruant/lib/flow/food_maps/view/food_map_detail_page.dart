import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../features/component/component_barrel.dart';
import '../../../features/component/rating_stars.dart';
import '../../../features/foundation/extension/extension_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../../gen/assets.gen.dart';
import '../../../generated/l10n.dart';
import '../../restaurant/view/view_barrel.dart';
import '../bloc/bloc_barrel.dart';
import '../model/food_map_member_style.dart';
import 'food_map_map_view.dart';
import 'food_maps_page.dart';
import 'import_favorites_sheet.dart';

/// 成員決定性色標與首字母頭像徽章。
class FoodMapMemberAvatar extends StatelessWidget {
  final String uid;
  final String name;
  final double radius;

  const FoodMapMemberAvatar({
    super.key,
    required this.uid,
    required this.name,
    this.radius = ThemeSize.size14,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: FoodMapMemberStyle.colorForUid(uid),
      child: Text(
        FoodMapMemberStyle.initialForName(name),
        style: TextStyle(
          color: ThemeColor.colorffffff,
          fontSize: radius * 0.9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 單一共編美食地圖詳情頁（支援行動平台列表／地圖雙視圖、投票、短評編輯與最愛匯入）。
class FoodMapDetailPage extends StatefulWidget {
  static const routeName = '/FoodMapDetailPage';

  const FoodMapDetailPage({super.key});

  @override
  State<FoodMapDetailPage> createState() => _FoodMapDetailPageState();
}

class _FoodMapDetailPageState extends State<FoodMapDetailPage> {
  late FoodMapDetailBloc _bloc;
  FoodMapEntity? _initialMap;
  bool _isInit = false;
  bool _isMapView = false;

  @override
  void initState() {
    super.initState();
    _bloc = BlocProvider.of<FoodMapDetailBloc>(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is FoodMapEntity) {
        _initialMap = args;
        _bloc.add(LoadFoodMapDetail(mapId: args.id, initialMap: args));
      }
      _isInit = true;
    }
  }

  FoodMapEntity? _resolveActiveMap(FoodMapDetailState state) => switch (state) {
    FoodMapDetailLoaded(:final map) => map,
    FoodMapDetailLoading(:final initialMap) => initialMap ?? _initialMap,
    FoodMapDetailFailure(:final initialMap) => initialMap ?? _initialMap,
    FoodMapDetailInitial() => _initialMap,
  };

  Future<void> _onRefresh(String mapId) {
    final completer = Completer<void>();
    _bloc.add(RefreshFoodMapDetail(mapId: mapId, completer: completer));
    return completer.future;
  }

  Future<void> _copyInviteCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    context.showAppSnackBar(S.current.food_maps_code_copied(code));
  }

  Future<void> _openImportFavorites(
    String mapId,
    List<FoodMapItemEntity> items,
  ) async {
    final existingIds = items.map((e) => e.restaurantId).toSet();
    final imported = await ImportFavoritesSheet.show(
      context,
      mapId: mapId,
      existingRestaurantIds: existingIds,
    );
    if (imported == true && mounted) {
      _bloc.add(RefreshFoodMapDetail(mapId: mapId));
    }
  }

  Future<void> _editNote(String mapId, FoodMapItemEntity item) async {
    final updatedNote = await showDialog<String>(
      context: context,
      builder: (_) => _EditItemNoteDialog(initialNote: item.note),
    );
    if (updatedNote == null || !mounted) return;
    _bloc.add(
      UpdateFoodMapItemNoteRequested(
        mapId: mapId,
        restaurantId: item.restaurantId,
        note: updatedNote,
      ),
    );
  }

  Future<void> _confirmRemoveItem(String mapId, FoodMapItemEntity item) async {
    final name = item.restaurant.name ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.current.food_maps_remove_restaurant),
        content: Text(S.current.food_maps_remove_restaurant_confirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(S.current.cancel),
          ),
          FilledButton(
            key: const Key('food_map_confirm_remove_item_btn'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(S.current.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _bloc.add(
      RemoveFoodMapItemRequested(mapId: mapId, restaurantId: item.restaurantId),
    );
  }

  void _openRestaurantDetail(FoodMapItemEntity item) {
    unawaited(
      Navigator.of(context).pushNamed(
        RestaurantDetailPage.routeName,
        arguments: Tuple2<RestaurantEntity, dynamic>(item.restaurant, null),
      ),
    );
  }

  void _handleFeedback(BuildContext context, FoodMapDetailFeedback feedback) {
    switch (feedback) {
      case FoodMapNoteUpdatedFeedback():
        context.showAppSnackBar(S.current.food_maps_note_updated);
      case FoodMapItemRemovedFeedback():
        context.showAppSnackBar(S.current.food_maps_restaurant_removed);
      case FoodMapDetailActionErrorFeedback(:final errorCode):
        context.showAppSnackBar(foodMapErrorMessage(errorCode));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUseMapMode = platformCapabilities().mapMode;

    return BlocConsumer<FoodMapDetailBloc, FoodMapDetailState>(
      bloc: _bloc,
      listenWhen: (previous, current) =>
          current is FoodMapDetailLoaded &&
          current.feedback != null &&
          (previous is! FoodMapDetailLoaded ||
              previous.feedback != current.feedback),
      listener: (context, state) {
        if (state is FoodMapDetailLoaded) {
          final feedback = state.feedback;
          if (feedback != null) {
            _handleFeedback(context, feedback);
          }
        }
      },
      builder: (context, state) {
        final activeMap = _resolveActiveMap(state);
        final loadedItems = state is FoodMapDetailLoaded
            ? state.items
            : const <FoodMapItemEntity>[];

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: ThemeColor.colorffffff),
            ),
            title: Text(
              activeMap?.title ?? S.current.food_maps_title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ThemeColor.colorffffff,
                fontSize: ThemeFontSize.fontSize20,
              ),
            ),
            backgroundColor: ThemeColor.colord84a20,
            actions: [
              if (activeMap != null && activeMap.inviteCode.isNotEmpty)
                IconButton(
                  key: const Key('food_map_detail_copy_code_btn'),
                  tooltip: S.current.food_maps_copy_code_tooltip,
                  onPressed: () => _copyInviteCode(activeMap.inviteCode),
                  icon: const Icon(Icons.copy, color: ThemeColor.colorffffff),
                ),
              if (state is FoodMapDetailLoaded)
                IconButton(
                  key: const Key('food_map_import_favorites_btn'),
                  tooltip: S.current.food_maps_import_favorites_action,
                  onPressed: () =>
                      _openImportFavorites(state.map.id, loadedItems),
                  icon: const Icon(
                    Icons.favorite_outline,
                    color: ThemeColor.colorffffff,
                  ),
                ),
              if (canUseMapMode && state is FoodMapDetailLoaded)
                IconButton(
                  key: const Key('food_map_detail_toggle_view_btn'),
                  tooltip: _isMapView
                      ? S.current.food_maps_toggle_list_view
                      : S.current.food_maps_toggle_map_view,
                  onPressed: () => setState(() => _isMapView = !_isMapView),
                  icon: Icon(
                    _isMapView ? Icons.list : Icons.map_outlined,
                    color: ThemeColor.colorffffff,
                  ),
                ),
            ],
          ),
          body: switch (state) {
            FoodMapDetailInitial() when _isInit && _initialMap == null =>
              EmptyDataWidget(
                title: foodMapErrorMessage(FoodMapErrorCode.mapNotFound),
                icon: Icons.error_outline,
              ),
            FoodMapDetailInitial() ||
            FoodMapDetailLoading() => const Center(child: LoadingWidget()),
            FoodMapDetailFailure(:final errorCode) => EmptyDataWidget(
              title: foodMapErrorMessage(errorCode),
              icon: Icons.error_outline,
              onRetry: activeMap == null
                  ? null
                  : () => _bloc.add(
                      LoadFoodMapDetail(
                        mapId: activeMap.id,
                        initialMap: activeMap,
                      ),
                    ),
            ),
            FoodMapDetailLoaded(:final map, :final items, :final currentUid) =>
              Column(
                children: [
                  FoodMapMembersStrip(map: map),
                  const Divider(height: 1),
                  Expanded(
                    child: items.isEmpty
                        ? _FoodMapDetailEmptyView(
                            onImportFavorites: () =>
                                _openImportFavorites(map.id, items),
                          )
                        : (canUseMapMode && _isMapView)
                        ? FoodMapMapView(
                            items: items,
                            onItemTap: _openRestaurantDetail,
                          )
                        : RefreshIndicator(
                            onRefresh: () => _onRefresh(map.id),
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(ThemeSize.space12),
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: ThemeSize.space10),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final canModify = item.canModify(
                                  currentUid,
                                  mapOwnerUid: map.ownerUid,
                                );
                                return FoodMapRestaurantCard(
                                  item: item,
                                  myVote: item.voteOf(currentUid),
                                  canModify: canModify,
                                  onTap: () => _openRestaurantDetail(item),
                                  onUpvote: () => _bloc.add(
                                    ToggleFoodMapItemVote(
                                      mapId: map.id,
                                      restaurantId: item.restaurantId,
                                      tappedVote: FoodMapVote.up,
                                    ),
                                  ),
                                  onDownvote: () => _bloc.add(
                                    ToggleFoodMapItemVote(
                                      mapId: map.id,
                                      restaurantId: item.restaurantId,
                                      tappedVote: FoodMapVote.down,
                                    ),
                                  ),
                                  onEditNote: canModify
                                      ? () => _editNote(map.id, item)
                                      : null,
                                  onRemove: canModify
                                      ? () => _confirmRemoveItem(map.id, item)
                                      : null,
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
          },
        );
      },
    );
  }
}

/// 詳情頁頂部成員色標橫列。
class FoodMapMembersStrip extends StatelessWidget {
  final FoodMapEntity map;

  const FoodMapMembersStrip({super.key, required this.map});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: ThemeSize.size52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeSize.space12,
          vertical: ThemeSize.space8,
        ),
        itemCount: map.memberUids.length,
        separatorBuilder: (_, __) => const SizedBox(width: ThemeSize.space8),
        itemBuilder: (context, index) {
          final uid = map.memberUids[index];
          final name = map.memberDisplayName(uid);
          final isOwner = map.isOwner(uid);
          return Chip(
            visualDensity: VisualDensity.compact,
            avatar: FoodMapMemberAvatar(
              uid: uid,
              name: name,
              radius: ThemeSize.space10,
            ),
            label: Text(
              isOwner ? '$name (${S.current.food_maps_owner_badge})' : name,
              style: textTheme.labelMedium,
            ),
          );
        },
      ),
    );
  }
}

/// 列表模式下的共編地圖餐廳卡片。
class FoodMapRestaurantCard extends StatelessWidget {
  final FoodMapItemEntity item;
  final FoodMapVote myVote;
  final bool canModify;
  final VoidCallback onTap;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;
  final VoidCallback? onEditNote;
  final VoidCallback? onRemove;

  const FoodMapRestaurantCard({
    super.key,
    required this.item,
    required this.myVote,
    required this.canModify,
    required this.onTap,
    required this.onUpvote,
    required this.onDownvote,
    this.onEditNote,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final restaurant = item.restaurant;
    final imageUrl = (restaurant.imageUrl ?? '').trim();
    final metaParts = [
      (restaurant.price ?? '').trim(),
      restaurant.categoriesStr.trim(),
    ].where((p) => p.isNotEmpty).join(' · ');

    return Card(
      key: Key('food_map_item_card_${item.restaurantId}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(ThemeSize.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ThemeSize.radius8),
                    child: SizedBox(
                      width: ThemeSize.size64,
                      height: ThemeSize.size64,
                      child: imageUrl.isEmpty
                          ? Assets.images.empty.image(fit: BoxFit.cover)
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Assets.images.empty.image(fit: BoxFit.cover),
                            ),
                    ),
                  ),
                  const SizedBox(width: ThemeSize.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: ThemeSize.space4),
                        Row(
                          children: [
                            RatingStars(rating: restaurant.rating ?? 0),
                            const SizedBox(width: ThemeSize.space5),
                            Text(
                              (restaurant.rating ?? 0).toStringAsFixed(1),
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (metaParts.isNotEmpty) ...[
                          const SizedBox(height: ThemeSize.space3),
                          Text(
                            metaParts,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ThemeSize.space10),
              Row(
                children: [
                  FoodMapMemberAvatar(
                    uid: item.addedByUid,
                    name: item.addedByName,
                    radius: ThemeSize.space10,
                  ),
                  const SizedBox(width: ThemeSize.space8),
                  Expanded(
                    child: Text(
                      S.current.food_maps_recommended_by(item.addedByName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              if (item.note.isNotEmpty) ...[
                const SizedBox(height: ThemeSize.space8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(ThemeSize.space8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(ThemeSize.radius8),
                  ),
                  child: Text(item.note, style: textTheme.bodyMedium),
                ),
              ],
              const SizedBox(height: ThemeSize.space8),
              Row(
                children: [
                  _VoteButton(
                    key: Key('food_map_upvote_${item.restaurantId}'),
                    icon: myVote == FoodMapVote.up
                        ? Icons.thumb_up
                        : Icons.thumb_up_outlined,
                    count: item.upvoteCount,
                    isSelected: myVote == FoodMapVote.up,
                    selectedColor: ThemeColor.colord84a20,
                    onPressed: onUpvote,
                  ),
                  const SizedBox(width: ThemeSize.space8),
                  _VoteButton(
                    key: Key('food_map_downvote_${item.restaurantId}'),
                    icon: myVote == FoodMapVote.down
                        ? Icons.thumb_down
                        : Icons.thumb_down_outlined,
                    count: item.downvoteCount,
                    isSelected: myVote == FoodMapVote.down,
                    selectedColor: colorScheme.error,
                    onPressed: onDownvote,
                  ),
                  const Spacer(),
                  if (canModify && onEditNote != null)
                    IconButton(
                      key: Key('food_map_edit_note_${item.restaurantId}'),
                      tooltip: S.current.food_maps_edit_note,
                      onPressed: onEditNote,
                      icon: const Icon(Icons.edit_note, size: ThemeSize.size20),
                    ),
                  if (canModify && onRemove != null)
                    IconButton(
                      key: Key('food_map_remove_${item.restaurantId}'),
                      tooltip: S.current.food_maps_remove_restaurant,
                      onPressed: onRemove,
                      icon: Icon(
                        Icons.delete_outline,
                        size: ThemeSize.size20,
                        color: colorScheme.error,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onPressed;

  const _VoteButton({
    super.key,
    required this.icon,
    required this.count,
    required this.isSelected,
    required this.selectedColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? selectedColor
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(ThemeSize.radiusTag),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeSize.space8,
          vertical: ThemeSize.space4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: ThemeSize.size18, color: color),
            const SizedBox(width: ThemeSize.space4),
            Text(
              '$count',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodMapDetailEmptyView extends StatelessWidget {
  final VoidCallback onImportFavorites;

  const _FoodMapDetailEmptyView({required this.onImportFavorites});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ThemeSize.space20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyDataWidget(
              title: S.current.food_maps_detail_empty,
              icon: Icons.add_location_alt_outlined,
            ),
            const SizedBox(height: ThemeSize.space16),
            FilledButton.icon(
              onPressed: onImportFavorites,
              icon: const Icon(Icons.favorite_outline),
              label: Text(S.current.food_maps_import_favorites_action),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditItemNoteDialog extends StatefulWidget {
  final String initialNote;

  const _EditItemNoteDialog({required this.initialNote});

  @override
  State<_EditItemNoteDialog> createState() => _EditItemNoteDialogState();
}

class _EditItemNoteDialogState extends State<_EditItemNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(S.current.food_maps_edit_note),
      content: TextField(
        key: const Key('food_map_edit_note_field'),
        controller: _controller,
        maxLength: FoodMapItemEntity.maxNoteLength,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: S.current.food_maps_note_label,
          hintText: S.current.food_maps_note_hint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.current.cancel),
        ),
        FilledButton(
          key: const Key('food_map_edit_note_submit_btn'),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(S.current.confirm),
        ),
      ],
    );
  }
}
