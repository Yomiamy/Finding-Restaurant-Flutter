import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../features/component/component_barrel.dart';
import '../../../features/foundation/extension/extension_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';
import '../bloc/bloc_barrel.dart';
import 'food_maps_page.dart';

/// 從個人最愛清單批次匯入餐廳至共編美食地圖的 BottomSheet。
class ImportFavoritesSheet extends StatefulWidget {
  final String mapId;
  final Set<String> existingRestaurantIds;
  final ImportFavoritesBloc? bloc;

  const ImportFavoritesSheet({
    super.key,
    required this.mapId,
    required this.existingRestaurantIds,
    this.bloc,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String mapId,
    required Set<String> existingRestaurantIds,
    ImportFavoritesBloc? bloc,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ThemeSize.space16),
        ),
      ),
      builder: (_) => ImportFavoritesSheet(
        mapId: mapId,
        existingRestaurantIds: existingRestaurantIds,
        bloc: bloc,
      ),
    );
  }

  @override
  State<ImportFavoritesSheet> createState() => _ImportFavoritesSheetState();
}

class _ImportFavoritesSheetState extends State<ImportFavoritesSheet> {
  late ImportFavoritesBloc _bloc;
  late bool _isLocalBloc;
  final Set<String> _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _initBloc();
  }

  @override
  void didUpdateWidget(covariant ImportFavoritesSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bloc != oldWidget.bloc) {
      if (_isLocalBloc) {
        unawaited(_bloc.close());
      }
      _initBloc();
    }
  }

  void _initBloc() {
    _isLocalBloc = widget.bloc == null;
    _bloc = widget.bloc ?? ImportFavoritesBloc.fromGetIt();
    _bloc.add(const LoadFavoritesForImport());
  }

  @override
  void dispose() {
    if (_isLocalBloc) {
      unawaited(_bloc.close());
    }
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _submit(List<RestaurantEntity> favorites) {
    final selected = favorites
        .where((r) => r.id != null && _selectedIds.contains(r.id))
        .toList();
    if (selected.isEmpty) return;
    _bloc.add(
      SubmitImportFavorites(mapId: widget.mapId, restaurants: selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ImportFavoritesBloc>.value(
      value: _bloc,
      child: BlocConsumer<ImportFavoritesBloc, ImportFavoritesState>(
        bloc: _bloc,
        listener: (context, state) {
          if (state is ImportFavoritesSuccess) {
            final messenger = ScaffoldMessenger.of(context);
            Navigator.of(context).pop(true);
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  S.current.food_maps_import_success(state.addedCount),
                ),
              ),
            );
          } else if (state is ImportFavoritesReady) {
            final code = state.errorCode;
            if (code != null) {
              context.showAppSnackBar(foodMapErrorMessage(code));
            }
          }
        },
        builder: (context, state) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(ThemeSize.space16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_outline,
                        color: ThemeColor.colord84a20,
                      ),
                      const SizedBox(width: ThemeSize.space8),
                      Expanded(
                        child: Text(
                          S.current.food_maps_import_favorites_title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: ThemeSize.space12),
                  switch (state) {
                    ImportFavoritesInitial() ||
                    ImportFavoritesLoading() => const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: ThemeSize.space20,
                      ),
                      child: Center(child: LoadingWidget()),
                    ),
                    ImportFavoritesFailure(:final errorCode) =>
                      EmptyDataWidget.withDefaults(
                        title: foodMapErrorMessage(errorCode),
                        onRetry: () =>
                            _bloc.add(const LoadFavoritesForImport()),
                      ),
                    ImportFavoritesSuccess() => const SizedBox.shrink(),
                    ImportFavoritesReady(
                      :final favorites,
                      :final isSubmitting,
                    ) =>
                      favorites.isEmpty
                          ? EmptyDataWidget(
                              title: S.current.food_maps_import_favorites_empty,
                              icon: Icons.favorite_border,
                            )
                          : _ImportFavoritesListBody(
                              favorites: favorites,
                              existingIds: widget.existingRestaurantIds,
                              selectedIds: _selectedIds,
                              isSubmitting: isSubmitting,
                              onToggle: _toggleSelection,
                              onSubmit: () => _submit(favorites),
                            ),
                  },
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ImportFavoritesListBody extends StatelessWidget {
  final List<RestaurantEntity> favorites;
  final Set<String> existingIds;
  final Set<String> selectedIds;
  final bool isSubmitting;
  final ValueChanged<String> onToggle;
  final VoidCallback onSubmit;

  const _ImportFavoritesListBody({
    required this.favorites,
    required this.existingIds,
    required this.selectedIds,
    required this.isSubmitting,
    required this.onToggle,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: ThemeSize.size320),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final restaurant = favorites[index];
              final id = (restaurant.id ?? '').trim();
              final isAlreadyAdded = id.isEmpty || existingIds.contains(id);
              final isChecked = isAlreadyAdded || selectedIds.contains(id);

              return CheckboxListTile(
                key: Key('import_favorite_tile_$id'),
                contentPadding: EdgeInsets.zero,
                value: isChecked,
                onChanged: (isAlreadyAdded || isSubmitting)
                    ? null
                    : (_) => onToggle(id),
                title: Text(restaurant.name ?? ''),
                subtitle: isAlreadyAdded
                    ? Text(S.current.food_maps_import_already_added)
                    : (restaurant.categoriesStr.isNotEmpty
                          ? Text(restaurant.categoriesStr)
                          : null),
              );
            },
          ),
        ),
        const SizedBox(height: ThemeSize.space12),
        FilledButton(
          key: const Key('import_favorites_submit_btn'),
          onPressed: (selectedIds.isEmpty || isSubmitting) ? null : onSubmit,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, ThemeSize.size48),
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: ThemeSize.size20,
                  height: ThemeSize.size20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(S.current.food_maps_import_submit(selectedIds.length)),
        ),
      ],
    );
  }
}
