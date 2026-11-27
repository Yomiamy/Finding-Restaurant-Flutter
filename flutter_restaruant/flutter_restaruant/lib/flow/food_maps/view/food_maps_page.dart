import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../features/component/component_barrel.dart';
import '../../../features/foundation/extension/extension_barrel.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';
import '../bloc/bloc_barrel.dart';
import 'food_map_detail_page.dart';

/// 將共編美食地圖錯誤碼映射為多國語系提示文案。
String foodMapErrorMessage(FoodMapErrorCode code) => switch (code) {
  FoodMapErrorCode.invalidInput => S.current.food_maps_error_invalid_input,
  FoodMapErrorCode.invalidInviteCode =>
    S.current.food_maps_error_invalid_invite_code,
  FoodMapErrorCode.mapNotFound => S.current.food_maps_error_map_not_found,
  FoodMapErrorCode.itemNotFound => S.current.food_maps_error_item_not_found,
  FoodMapErrorCode.permissionDenied =>
    S.current.food_maps_error_permission_denied,
  FoodMapErrorCode.inviteCodeGenerationFailed ||
  FoodMapErrorCode.unknown => S.current.food_maps_error_generic,
};

/// 共編美食地圖清單頁面。
class FoodMapsPage extends StatefulWidget {
  static const routeName = '/FoodMapsPage';

  const FoodMapsPage({super.key});

  @override
  State<FoodMapsPage> createState() => _FoodMapsPageState();
}

class _FoodMapsPageState extends State<FoodMapsPage> {
  late FoodMapsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = BlocProvider.of<FoodMapsBloc>(context);
    _bloc.add(const FetchFoodMaps());
  }

  Future<void> _onRefresh() {
    final completer = Completer<void>();
    _bloc.add(RefreshFoodMaps(completer: completer));
    return completer.future;
  }

  Future<void> _copyInviteCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    context.showAppSnackBar(S.current.food_maps_code_copied(code));
  }

  Future<void> _openDetail(FoodMapEntity map) async {
    await Navigator.of(
      context,
    ).pushNamed(FoodMapDetailPage.routeName, arguments: map);
    if (!mounted) return;
    _bloc.add(const RefreshFoodMaps());
  }

  Future<void> _showCreateDialog() async {
    final result = await showDialog<({String title, String description})>(
      context: context,
      builder: (_) => const _CreateFoodMapDialog(),
    );
    if (result == null || !mounted) return;
    _bloc.add(
      CreateFoodMapRequested(
        title: result.title,
        description: result.description,
      ),
    );
  }

  Future<void> _showJoinDialog() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _JoinFoodMapDialog(),
    );
    if (code == null || !mounted) return;
    _bloc.add(JoinFoodMapByCodeRequested(inviteCode: code));
  }

  Future<void> _confirmDelete(FoodMapEntity map) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.current.food_maps_delete_map),
        content: Text(S.current.food_maps_delete_confirm(map.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(S.current.cancel),
          ),
          FilledButton(
            key: const Key('food_maps_confirm_delete_btn'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(S.current.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _bloc.add(DeleteFoodMapRequested(mapId: map.id));
  }

  Future<void> _confirmLeave(FoodMapEntity map) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.current.food_maps_leave_map),
        content: Text(S.current.food_maps_leave_confirm(map.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(S.current.cancel),
          ),
          FilledButton(
            key: const Key('food_maps_confirm_leave_btn'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(S.current.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _bloc.add(LeaveFoodMapRequested(mapId: map.id));
  }

  void _handleFeedback(BuildContext context, FoodMapsFeedback feedback) {
    switch (feedback) {
      case FoodMapCreatedFeedback(:final map):
        context.showAppSnackBar(S.current.food_maps_created_success(map.title));
      case FoodMapJoinedFeedback(:final map, :final alreadyMember):
        final message = alreadyMember
            ? S.current.food_maps_already_member(map.title)
            : S.current.food_maps_joined_success(map.title);
        context.showAppSnackBar(message);
      case FoodMapDeletedFeedback():
        context.showAppSnackBar(S.current.food_maps_deleted_success);
      case FoodMapLeftFeedback():
        context.showAppSnackBar(S.current.food_maps_left_success);
      case FoodMapsActionErrorFeedback(:final errorCode):
        context.showAppSnackBar(foodMapErrorMessage(errorCode));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: ThemeColor.colorffffff),
        ),
        title: Text(
          S.current.food_maps_title,
          style: const TextStyle(
            color: ThemeColor.colorffffff,
            fontSize: ThemeFontSize.fontSize22,
          ),
        ),
        backgroundColor: ThemeColor.colord84a20,
        actions: [
          IconButton(
            key: const Key('food_maps_join_btn'),
            tooltip: S.current.food_maps_join_action,
            onPressed: _showJoinDialog,
            icon: const Icon(
              Icons.group_add_outlined,
              color: ThemeColor.colorffffff,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('food_maps_create_btn'),
        onPressed: _showCreateDialog,
        backgroundColor: ThemeColor.colord84a20,
        foregroundColor: ThemeColor.colorffffff,
        icon: const Icon(Icons.add),
        label: Text(S.current.food_maps_create_action),
      ),
      body: BlocConsumer<FoodMapsBloc, FoodMapsState>(
        bloc: _bloc,
        listenWhen: (previous, current) =>
            current is FoodMapsLoaded &&
            current.feedback != null &&
            (previous is! FoodMapsLoaded ||
                previous.feedback != current.feedback),
        listener: (context, state) {
          if (state is FoodMapsLoaded) {
            final feedback = state.feedback;
            if (feedback != null) {
              _handleFeedback(context, feedback);
            }
          }
        },
        builder: (context, state) {
          return switch (state) {
            FoodMapsInitial() ||
            FoodMapsLoading() => const Center(child: LoadingWidget()),
            FoodMapsFailure(:final errorCode) => EmptyDataWidget.withDefaults(
              title: foodMapErrorMessage(errorCode),
              onRetry: () => _bloc.add(const FetchFoodMaps()),
            ),
            FoodMapsLoaded(:final maps, :final currentUid) =>
              maps.isEmpty
                  ? _FoodMapsEmptyView(
                      onCreate: _showCreateDialog,
                      onJoin: _showJoinDialog,
                    )
                  : RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          ThemeSize.space12,
                          ThemeSize.space12,
                          ThemeSize.space12,
                          ThemeSize.space64 + ThemeSize.space20,
                        ),
                        itemCount: maps.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: ThemeSize.space10),
                        itemBuilder: (context, index) {
                          final map = maps[index];
                          final isOwner = map.isOwner(currentUid);
                          return FoodMapSummaryCard(
                            map: map,
                            isOwner: isOwner,
                            onTap: () => _openDetail(map),
                            onCopyCode: () => _copyInviteCode(map.inviteCode),
                            onDeleteOrLeave: () => isOwner
                                ? _confirmDelete(map)
                                : _confirmLeave(map),
                          );
                        },
                      ),
                    ),
          };
        },
      ),
    );
  }
}

/// 單一共編美食地圖摘要卡片。
class FoodMapSummaryCard extends StatelessWidget {
  final FoodMapEntity map;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback onCopyCode;
  final VoidCallback onDeleteOrLeave;

  const FoodMapSummaryCard({
    super.key,
    required this.map,
    required this.isOwner,
    required this.onTap,
    required this.onCopyCode,
    required this.onDeleteOrLeave,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      key: Key('food_map_card_${map.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(ThemeSize.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      map.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isOwner)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ThemeSize.space8,
                        vertical: ThemeSize.space3,
                      ),
                      decoration: BoxDecoration(
                        color: ThemeColor.colord84a20.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(
                          ThemeSize.radiusTag,
                        ),
                      ),
                      child: Text(
                        S.current.food_maps_owner_badge,
                        style: textTheme.labelSmall?.copyWith(
                          color: ThemeColor.colord84a20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  IconButton(
                    key: Key('food_map_action_${map.id}'),
                    tooltip: isOwner
                        ? S.current.food_maps_delete_map
                        : S.current.food_maps_leave_map,
                    onPressed: onDeleteOrLeave,
                    icon: Icon(
                      isOwner ? Icons.delete_outline : Icons.logout,
                      color: colorScheme.onSurfaceVariant,
                      size: ThemeSize.size20,
                    ),
                  ),
                ],
              ),
              if (map.description.isNotEmpty) ...[
                const SizedBox(height: ThemeSize.space4),
                Text(
                  map.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: ThemeSize.space10),
              Wrap(
                spacing: ThemeSize.space8,
                runSpacing: ThemeSize.space5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MetaChip(
                    icon: Icons.people_outline,
                    label: S.current.food_maps_member_count(map.memberCount),
                  ),
                  _MetaChip(
                    icon: Icons.restaurant_outlined,
                    label: S.current.food_maps_item_count(map.itemCount),
                  ),
                  if (map.inviteCode.isNotEmpty)
                    ActionChip(
                      key: Key('food_map_copy_code_${map.id}'),
                      avatar: const Icon(Icons.copy, size: ThemeSize.size16),
                      label: Text(map.inviteCode),
                      tooltip: S.current.food_maps_copy_code_tooltip,
                      onPressed: onCopyCode,
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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: ThemeSize.size16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: ThemeSize.space4),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FoodMapsEmptyView extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _FoodMapsEmptyView({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ThemeSize.space20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyDataWidget(
              title: S.current.food_maps_empty_title,
              subtitle: S.current.food_maps_empty_subtitle,
              icon: Icons.edit_location_alt_outlined,
            ),
            const SizedBox(height: ThemeSize.space16),
            Wrap(
              spacing: ThemeSize.space12,
              runSpacing: ThemeSize.space8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: Text(S.current.food_maps_create_action),
                ),
                OutlinedButton.icon(
                  onPressed: onJoin,
                  icon: const Icon(Icons.group_add_outlined),
                  label: Text(S.current.food_maps_join_action),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateFoodMapDialog extends StatefulWidget {
  const _CreateFoodMapDialog();

  @override
  State<_CreateFoodMapDialog> createState() => _CreateFoodMapDialogState();
}

class _CreateFoodMapDialogState extends State<_CreateFoodMapDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(
      context,
    ).pop((title: title, description: _descController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.current.food_maps_create_dialog_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('food_maps_create_title_field'),
            controller: _titleController,
            maxLength: FoodMapEntity.maxTitleLength,
            decoration: InputDecoration(
              labelText: S.current.food_maps_name_label,
              hintText: S.current.food_maps_name_hint,
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: ThemeSize.space8),
          TextField(
            key: const Key('food_maps_create_desc_field'),
            controller: _descController,
            maxLength: FoodMapEntity.maxDescriptionLength,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: S.current.food_maps_description_label,
              hintText: S.current.food_maps_description_hint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.current.cancel),
        ),
        FilledButton(
          key: const Key('food_maps_create_submit_btn'),
          onPressed: _submit,
          child: Text(S.current.confirm),
        ),
      ],
    );
  }
}

class _JoinFoodMapDialog extends StatefulWidget {
  const _JoinFoodMapDialog();

  @override
  State<_JoinFoodMapDialog> createState() => _JoinFoodMapDialogState();
}

class _JoinFoodMapDialogState extends State<_JoinFoodMapDialog> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.current.food_maps_join_dialog_title),
      content: TextField(
        key: const Key('food_maps_join_code_field'),
        controller: _codeController,
        maxLength: FoodMapEntity.inviteCodeLength,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          labelText: S.current.food_maps_invite_code_label,
          hintText: S.current.food_maps_invite_code_hint,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.current.cancel),
        ),
        FilledButton(
          key: const Key('food_maps_join_submit_btn'),
          onPressed: _submit,
          child: Text(S.current.confirm),
        ),
      ],
    );
  }
}
