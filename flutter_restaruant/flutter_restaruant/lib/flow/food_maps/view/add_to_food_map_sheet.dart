import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../features/component/component_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';
import '../bloc/bloc_barrel.dart';
import 'food_maps_page.dart';

/// 從餐廳詳情頁彈出之「加入共編美食地圖」BottomSheet。
class AddToFoodMapSheet extends StatefulWidget {
  final RestaurantEntity restaurant;
  final AddToFoodMapBloc? bloc;

  const AddToFoodMapSheet({super.key, required this.restaurant, this.bloc});

  static Future<void> show(
    BuildContext context, {
    required RestaurantEntity restaurant,
    AddToFoodMapBloc? bloc,
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
      builder: (_) => AddToFoodMapSheet(restaurant: restaurant, bloc: bloc),
    );
  }

  @override
  State<AddToFoodMapSheet> createState() => _AddToFoodMapSheetState();
}

class _AddToFoodMapSheetState extends State<AddToFoodMapSheet> {
  late AddToFoodMapBloc _bloc;
  late bool _isLocalBloc;

  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _selectedMapId;
  bool _isCreatingNew = false;
  Set<String> _knownMapIds = <String>{};

  @override
  void initState() {
    super.initState();
    _initBloc();
  }

  @override
  void didUpdateWidget(covariant AddToFoodMapSheet oldWidget) {
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
    _bloc = widget.bloc ?? AddToFoodMapBloc.fromGetIt();
    _bloc.add(const LoadMapsForAdd());
  }

  @override
  void dispose() {
    _noteController.dispose();
    _titleController.dispose();
    _descController.dispose();
    if (_isLocalBloc) {
      unawaited(_bloc.close());
    }
    super.dispose();
  }

  void _submit(List<FoodMapEntity> maps) {
    if (_isCreatingNew || maps.isEmpty) {
      _bloc.add(
        CreateMapAndAddRestaurant(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          restaurant: widget.restaurant,
          note: _noteController.text.trim(),
        ),
      );
      return;
    }

    final selectedId = _selectedMapId ?? maps.first.id;
    final selectedMap = maps.firstWhere(
      (m) => m.id == selectedId,
      orElse: () => maps.first,
    );
    _bloc.add(
      SubmitAddRestaurantToMap(
        mapId: selectedMap.id,
        mapTitle: selectedMap.title,
        restaurant: widget.restaurant,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocProvider<AddToFoodMapBloc>.value(
      value: _bloc,
      child: BlocConsumer<AddToFoodMapBloc, AddToFoodMapState>(
        bloc: _bloc,
        listener: (context, state) {
          if (state is AddToFoodMapSuccess) {
            final message = state.alreadyExists
                ? S.current.food_maps_already_in_map(state.mapTitle)
                : S.current.food_maps_added_success(state.mapTitle);
            final messenger = ScaffoldMessenger.of(context);
            Navigator.of(context).pop();
            messenger.showSnackBar(SnackBar(content: Text(message)));
          } else if (state is AddToFoodMapReady) {
            final currentIds = state.maps.map((m) => m.id).toSet();
            final hasNewCreatedMap =
                _isCreatingNew &&
                state.maps.isNotEmpty &&
                !_knownMapIds.contains(state.maps.first.id);
            _knownMapIds = currentIds;
            if (hasNewCreatedMap) {
              setState(() {
                _isCreatingNew = false;
                _selectedMapId = state.maps.first.id;
              });
            } else if (state.maps.isNotEmpty &&
                !state.maps.any((m) => m.id == _selectedMapId)) {
              setState(() => _selectedMapId = state.maps.first.id);
            }
          }
        },
        builder: (context, state) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                ThemeSize.space16,
                ThemeSize.space12,
                ThemeSize.space16,
                ThemeSize.space16 + bottomInset,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SheetHeader(title: S.current.food_maps_add_sheet_title),
                    const SizedBox(height: ThemeSize.space12),
                    switch (state) {
                      AddToFoodMapInitial() ||
                      AddToFoodMapLoading() => const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: ThemeSize.space20,
                        ),
                        child: Center(child: LoadingWidget()),
                      ),
                      AddToFoodMapFailure(:final errorCode) => EmptyDataWidget(
                        title: foodMapErrorMessage(errorCode),
                        icon: Icons.error_outline,
                        onRetry: () => _bloc.add(const LoadMapsForAdd()),
                      ),
                      AddToFoodMapSuccess() => const SizedBox.shrink(),
                      AddToFoodMapReady(
                        :final maps,
                        :final isSubmitting,
                        :final errorCode,
                      ) =>
                        _AddToFoodMapBody(
                          maps: maps,
                          selectedMapId:
                              _selectedMapId ??
                              (maps.isNotEmpty ? maps.first.id : null),
                          isCreatingNew: _isCreatingNew || maps.isEmpty,
                          isSubmitting: isSubmitting,
                          errorCode: errorCode,
                          titleController: _titleController,
                          descController: _descController,
                          noteController: _noteController,
                          onSelectMap: (id) => setState(() {
                            _selectedMapId = id;
                            _isCreatingNew = false;
                          }),
                          onToggleCreateNew: maps.isEmpty
                              ? null
                              : () => setState(
                                  () => _isCreatingNew = !_isCreatingNew,
                                ),
                          onSubmit: () => _submit(maps),
                        ),
                    },
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;

  const _SheetHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.add_location_alt_outlined,
          color: ThemeColor.colord84a20,
        ),
        const SizedBox(width: ThemeSize.space8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class _AddToFoodMapBody extends StatelessWidget {
  final List<FoodMapEntity> maps;
  final String? selectedMapId;
  final bool isCreatingNew;
  final bool isSubmitting;
  final FoodMapErrorCode? errorCode;
  final TextEditingController titleController;
  final TextEditingController descController;
  final TextEditingController noteController;
  final ValueChanged<String> onSelectMap;
  final VoidCallback? onToggleCreateNew;
  final VoidCallback onSubmit;

  const _AddToFoodMapBody({
    required this.maps,
    required this.selectedMapId,
    required this.isCreatingNew,
    required this.isSubmitting,
    required this.errorCode,
    required this.titleController,
    required this.descController,
    required this.noteController,
    required this.onSelectMap,
    required this.onToggleCreateNew,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorCode case final code?) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: ThemeSize.space8),
            child: Text(
              foodMapErrorMessage(code),
              key: const Key('add_to_food_map_error_text'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ),
        ],
        if (maps.isNotEmpty && !isCreatingNew) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: ThemeSize.size220),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: maps.length,
              itemBuilder: (context, index) {
                final map = maps[index];
                final isSelected = map.id == selectedMapId;
                return ListTile(
                  key: Key('add_to_food_map_option_${map.id}'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? ThemeColor.colord84a20
                        : colorScheme.onSurfaceVariant,
                  ),
                  title: Text(map.title),
                  subtitle: Text(S.current.food_maps_item_count(map.itemCount)),
                  onTap: isSubmitting ? null : () => onSelectMap(map.id),
                );
              },
            ),
          ),
          if (onToggleCreateNew != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('add_to_food_map_switch_create_btn'),
                onPressed: isSubmitting ? null : onToggleCreateNew,
                icon: const Icon(Icons.add),
                label: Text(S.current.food_maps_add_sheet_create_new),
              ),
            ),
        ],
        if (isCreatingNew) ...[
          if (onToggleCreateNew != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: isSubmitting ? null : onToggleCreateNew,
                icon: const Icon(Icons.arrow_back),
                label: Text(S.current.food_maps_title),
              ),
            ),
          TextField(
            key: const Key('add_to_food_map_new_title_field'),
            controller: titleController,
            enabled: !isSubmitting,
            maxLength: FoodMapEntity.maxTitleLength,
            decoration: InputDecoration(
              labelText: S.current.food_maps_name_label,
              hintText: S.current.food_maps_name_hint,
            ),
          ),
          const SizedBox(height: ThemeSize.space8),
          TextField(
            key: const Key('add_to_food_map_new_desc_field'),
            controller: descController,
            enabled: !isSubmitting,
            maxLength: FoodMapEntity.maxDescriptionLength,
            decoration: InputDecoration(
              labelText: S.current.food_maps_description_label,
              hintText: S.current.food_maps_description_hint,
            ),
          ),
        ],
        const SizedBox(height: ThemeSize.space8),
        TextField(
          key: const Key('add_to_food_map_note_field'),
          controller: noteController,
          enabled: !isSubmitting,
          maxLength: FoodMapItemEntity.maxNoteLength,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: S.current.food_maps_note_label,
            hintText: S.current.food_maps_note_hint,
          ),
        ),
        const SizedBox(height: ThemeSize.space12),
        FilledButton(
          key: const Key('add_to_food_map_submit_btn'),
          onPressed: isSubmitting ? null : onSubmit,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, ThemeSize.size48),
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: ThemeSize.size20,
                  height: ThemeSize.size20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  isCreatingNew
                      ? S.current.food_maps_add_sheet_create_new
                      : S.current.food_maps_add_sheet_submit,
                ),
        ),
      ],
    );
  }
}
