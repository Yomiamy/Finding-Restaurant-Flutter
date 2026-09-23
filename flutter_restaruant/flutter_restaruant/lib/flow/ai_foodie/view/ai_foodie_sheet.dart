import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../features/utils/utils_barrel.dart';

import '../../../domain/entities/entities_barrel.dart'
    show RestaurantEntity, RestaurantLocationEntity;
import '../../../domain/repositories/ai_foodie_repository.dart';
import '../../../features/foundation/foundation_barrel.dart';
import '../../restaurant/view/restaurant_detail_page.dart';
import '../bloc/bloc_barrel.dart';
import '../model/ai_foodie_model.dart';
import '../../../generated/l10n.dart';
import 'action_chip_group_widget.dart';
import 'comparison_matrix_card.dart';
import 'decision_roulette_dialog.dart';

/// AI 覓食助理底部對話畫布視窗
class AiFoodieSheet extends StatefulWidget {
  const AiFoodieSheet({super.key, this.bloc, this.candidateRestaurants});

  final AiFoodieBloc? bloc;
  final List<RestaurantEntity>? candidateRestaurants;

  static Future<void> show(
    BuildContext context, {
    AiFoodieBloc? bloc,
    List<RestaurantEntity>? candidateRestaurants,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AiFoodieSheet(bloc: bloc, candidateRestaurants: candidateRestaurants),
    );
  }

  @override
  State<AiFoodieSheet> createState() => _AiFoodieSheetState();
}

class _AiFoodieSheetState extends State<AiFoodieSheet> {
  late final AiFoodieBloc _bloc;
  final TextEditingController _textController = TextEditingController();
  ScrollController? _sheetScrollController;

  @override
  void initState() {
    super.initState();
    _bloc =
        widget.bloc ??
        AiFoodieBloc(
          repository: GetIt.I<AiFoodieRepository>(),
          candidateRestaurants: widget.candidateRestaurants,
        );
    _bloc.add(const LoadInitialSuggestions());
  }

  @override
  void dispose() {
    _textController.dispose();
    if (widget.bloc == null) {
      _bloc.close();
    }
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _sheetScrollController;
      if (controller != null && controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _navigateToRestaurantDetail(ComparisonItemModel item) {
    final entity = RestaurantEntity(
      id: item.id,
      name: item.name,
      rating: item.rating,
      price: item.price,
      imageUrl: item.imageUrl,
      location: item.address != null
          ? RestaurantLocationEntity(address1: item.address)
          : null,
    );
    final arguments = Tuple2<RestaurantEntity, dynamic>(entity, null);
    Navigator.of(
      context,
    ).pushNamed(RestaurantDetailPage.routeName, arguments: arguments);
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _bloc.add(SendUserPrompt(text));
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<AiFoodieBloc, AiFoodieState>(
        listenWhen: (prev, curr) =>
            !prev.isRouletteVisible && curr.isRouletteVisible,
        listener: (context, state) {
          if (state.isRouletteVisible && state.rouletteOptions.isNotEmpty) {
            DecisionRouletteDialog.show(
              context,
              title: state.rouletteTitle ?? '今晚吃什麼？命運大轉盤',
              options: state.rouletteOptions,
              onWinnerSelected: (winner) {
                _bloc.add(SpinRouletteWinnerSelected(winner));
                _scrollToBottom();
              },
            );
          }
        },
        builder: (context, state) {
          return DraggableScrollableSheet(
            initialChildSize: 0.88,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              _sheetScrollController = scrollController;
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(ThemeSize.radiusTag),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: ThemeSize.space8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ThemeSize.space16,
                        vertical: ThemeSize.space8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(ThemeSize.space8),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              size: 20,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: ThemeSize.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  S.of(context).ai_foodie_sheet_title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  S.of(context).ai_foodie_sheet_subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: S.of(context).ai_foodie_reset_tooltip,
                            onPressed: () => _bloc.add(const ResetAiFoodie()),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: S.of(context).ai_foodie_close_tooltip,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Message List
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: ThemeSize.space16,
                          vertical: ThemeSize.space12,
                        ),
                        itemCount:
                            state.messageModels.length +
                            (state.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.messageModels.length) {
                            return const _LoadingMessageBubble();
                          }
                          final msg = state.messageModels[index];
                          return _MessageItem(
                            message: msg,
                            onChipTap: (chip) {
                              _bloc.add(TriggerActionChip(chip));
                              _scrollToBottom();
                            },
                            onRestaurantTap: _navigateToRestaurantDetail,
                          );
                        },
                      ),
                    ),
                    // Input Bar
                    Container(
                      padding: EdgeInsets.only(
                        left: ThemeSize.space16,
                        right: ThemeSize.space8,
                        top: ThemeSize.space8,
                        bottom:
                            MediaQuery.of(context).viewInsets.bottom +
                            ThemeSize.space12,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border(
                          top: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: InputDecoration(
                                hintText: S.of(context).ai_foodie_input_hint,
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.outline,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: ThemeSize.space16,
                                  vertical: ThemeSize.space12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    ThemeSize.radiusTag,
                                  ),
                                  borderSide: BorderSide(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: ThemeSize.space8),
                          IconButton.filled(
                            onPressed: state.isLoading ? null : _sendMessage,
                            icon: const Icon(Icons.arrow_upward_rounded),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  const _MessageItem({
    required this.message,
    required this.onChipTap,
    this.onRestaurantTap,
  });

  final AiFoodieMessageModel message;
  final void Function(ActionChipModel chip) onChipTap;
  final void Function(ComparisonItemModel item)? onRestaurantTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ThemeSize.space8),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: ThemeSize.space8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(ThemeSize.space12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(ThemeSize.radius12),
                  ),
                  child: Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUser
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // GenUI 動態元件宣告式渲染
          if (!isUser && message.components.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: message.components
                    .map((comp) {
                      return switch (comp) {
                        ComparisonMatrixModel() => ComparisonMatrixCard(
                          component: comp,
                          onRestaurantTap: onRestaurantTap,
                        ),
                        ActionChipGroupModel() => ActionChipGroupWidget(
                          component: comp,
                          onChipTap: onChipTap,
                        ),
                        DecisionRouletteModel() => Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: ThemeSize.space8,
                          ),
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.casino_rounded),
                            label: Text(comp.title),
                            onPressed: () {
                              onChipTap(
                                ActionChipModel(
                                  label: comp.title,
                                  action: 'open_roulette',
                                  payload: {
                                    'title': comp.title,
                                    'options': comp.options,
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        FallbackTextModel(:final text) => Padding(
                          padding: const EdgeInsets.all(ThemeSize.space8),
                          child: Text(
                            text,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      };
                    })
                    .toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadingMessageBubble extends StatelessWidget {
  const _LoadingMessageBubble();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ThemeSize.space8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.auto_awesome,
              size: 14,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: ThemeSize.space8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ThemeSize.space16,
              vertical: ThemeSize.space12,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(ThemeSize.radius12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: ThemeSize.space12),
                Text(
                  S.of(context).ai_foodie_loading_hint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
