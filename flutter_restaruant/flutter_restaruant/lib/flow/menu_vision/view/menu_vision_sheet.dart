import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../../domain/repositories/menu_vision_repository.dart';
import '../../../features/utils/utils_barrel.dart';
import '../../../generated/l10n.dart';
import '../bloc/menu_vision_bloc.dart';
import '../model/menu_vision_model.dart';
import 'dish_card.dart';

/// AI 拍菜單翻譯與過敏原拆解 Sheet
///
/// 拍照入口（標題列、初始／失敗／取消畫面與 [autoStartCapture]）只在具相機
/// 能力的平台出現（見 [platformCapabilities]）；其餘平台只提供相簿選圖。
class MenuVisionSheet extends StatefulWidget {
  final String restaurantTitle;
  final MenuVisionBloc? bloc;
  final bool autoStartCapture;

  const MenuVisionSheet({
    super.key,
    this.restaurantTitle = '',
    this.bloc,
    this.autoStartCapture = false,
  });

  static Future<void> show(
    BuildContext context, {
    String restaurantTitle = '',
    MenuVisionBloc? bloc,
    bool autoStartCapture = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => MenuVisionSheet(
        restaurantTitle: restaurantTitle,
        bloc: bloc,
        autoStartCapture: autoStartCapture,
      ),
    );
  }

  @override
  State<MenuVisionSheet> createState() => _MenuVisionSheetState();
}

class _MenuVisionSheetState extends State<MenuVisionSheet> {
  late final MenuVisionBloc _bloc;
  late final bool _isLocalBloc;
  late final VoidCallback? _onCamera;

  @override
  void initState() {
    super.initState();
    if (widget.bloc != null) {
      _bloc = widget.bloc!;
      _isLocalBloc = false;
    } else {
      _bloc = MenuVisionBloc(repository: GetIt.I<MenuVisionRepository>());
      _isLocalBloc = true;
    }

    // 無相機能力的平台（如 macOS）為 null：四個拍照入口與自動拍照一併消失。
    _onCamera = platformCapabilities().camera
        ? () =>
              _bloc.add(const CaptureAndAnalyzeMenu(source: ImageSource.camera))
        : null;

    if (widget.autoStartCapture) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onCamera?.call());
    }
  }

  @override
  void dispose() {
    if (_isLocalBloc) {
      _bloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Column(
          children: [
            _SheetHeader(
              restaurantTitle: widget.restaurantTitle,
              onCameraPressed: _onCamera,
              onGalleryPressed: () => _bloc.add(
                const CaptureAndAnalyzeMenu(source: ImageSource.gallery),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<MenuVisionBloc, MenuVisionState>(
                bloc: _bloc,
                builder: (context, state) {
                  return switch (state) {
                    MenuVisionInitial() => _InitialPromptView(
                      onCamera: _onCamera,
                      onGallery: () => _bloc.add(
                        const CaptureAndAnalyzeMenu(
                          source: ImageSource.gallery,
                        ),
                      ),
                    ),
                    MenuVisionLoading() => const _LoadingProgressView(),
                    MenuVisionSuccess(:final catalog) => _CatalogContentView(
                      catalog: catalog,
                    ),
                    MenuVisionFailure(
                      :final message,
                      :final failedImageBytes,
                    ) =>
                      _FailureRetryView(
                        message: message,
                        onRetryPhoto: failedImageBytes != null
                            ? () => _bloc.add(
                                RetryMenuAnalysis(imageBytes: failedImageBytes),
                              )
                            : null,
                        onRetryCamera: _onCamera,
                        onRetryGallery: () => _bloc.add(
                          const CaptureAndAnalyzeMenu(
                            source: ImageSource.gallery,
                          ),
                        ),
                      ),
                    MenuVisionCancelled() => _CancelledView(
                      onCamera: _onCamera,
                      onGallery: () => _bloc.add(
                        const CaptureAndAnalyzeMenu(
                          source: ImageSource.gallery,
                        ),
                      ),
                    ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String restaurantTitle;
  final VoidCallback? onCameraPressed;
  final VoidCallback onGalleryPressed;

  const _SheetHeader({
    required this.restaurantTitle,
    required this.onCameraPressed,
    required this.onGalleryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: theme.colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.current.menu_vision_title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (restaurantTitle.isNotEmpty)
                  Text(
                    restaurantTitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (onCameraPressed != null)
            IconButton(
              tooltip: S.current.menu_vision_tooltip_camera,
              icon: const Icon(Icons.camera_alt_outlined),
              onPressed: onCameraPressed,
            ),
          IconButton(
            tooltip: S.current.menu_vision_tooltip_gallery,
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: onGalleryPressed,
          ),
          IconButton(
            tooltip: S.current.menu_vision_tooltip_close,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _InitialPromptView extends StatelessWidget {
  final VoidCallback? onCamera;
  final VoidCallback onGallery;

  const _InitialPromptView({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              S.current.menu_vision_prompt_title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.current.menu_vision_prompt_subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            if (onCamera != null) ...[
              FilledButton.icon(
                key: const Key('take_photo_button'),
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt),
                label: Text(S.current.menu_vision_btn_camera),
                style: FilledButton.styleFrom(minimumSize: const Size(220, 48)),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              key: const Key('gallery_pick_button'),
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library),
              label: Text(S.current.menu_vision_btn_gallery),
              style: OutlinedButton.styleFrom(minimumSize: const Size(220, 48)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingProgressView extends StatelessWidget {
  const _LoadingProgressView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              S.current.menu_vision_loading_title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.current.menu_vision_loading_subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogContentView extends StatelessWidget {
  final DishCatalogModel catalog;

  const _CatalogContentView({required this.catalog});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dishes = catalog.dishes;

    if (dishes.isEmpty) {
      return Center(
        child: Text(
          S.current.menu_vision_empty_dishes,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // 依類別整理分頁：以「全部」為第一頁，後續為含有菜色的類別
    final availableCategories = DishCategory.values
        .where((cat) => dishes.any((d) => d.category == cat))
        .toList(growable: false);

    final tabCategories = <DishCategory?>[null, ...availableCategories];

    return DefaultTabController(
      length: tabCategories.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: tabCategories
                .map((cat) {
                  if (cat == null) {
                    return Tab(
                      text:
                          '${S.current.menu_vision_tab_all} (${dishes.length})',
                    );
                  }
                  final count = dishes.where((d) => d.category == cat).length;
                  return Tab(text: '${cat.displayName} ($count)');
                })
                .toList(growable: false),
          ),
          Expanded(
            child: TabBarView(
              children: tabCategories
                  .map((cat) {
                    final filteredDishes = cat == null
                        ? dishes
                        : dishes
                              .where((d) => d.category == cat)
                              .toList(growable: false);

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredDishes.length,
                      itemBuilder: (context, index) {
                        return DishCard(
                          dish: filteredDishes[index],
                          currency: catalog.currency,
                        );
                      },
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureRetryView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetryPhoto;
  final VoidCallback? onRetryCamera;
  final VoidCallback onRetryGallery;

  const _FailureRetryView({
    required this.message,
    this.onRetryPhoto,
    required this.onRetryCamera,
    required this.onRetryGallery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              S.current.menu_vision_failure_title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (onRetryPhoto != null) ...[
              FilledButton.icon(
                key: const Key('retry_photo_button'),
                onPressed: onRetryPhoto,
                icon: const Icon(Icons.refresh),
                label: Text(S.current.menu_vision_btn_retry_photo),
                style: FilledButton.styleFrom(minimumSize: const Size(220, 44)),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetryCamera != null) ...[
                  OutlinedButton.icon(
                    onPressed: onRetryCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(S.current.menu_vision_btn_retake),
                  ),
                  const SizedBox(width: 12),
                ],
                OutlinedButton.icon(
                  onPressed: onRetryGallery,
                  icon: const Icon(Icons.photo_library),
                  label: Text(S.current.menu_vision_btn_reselect_gallery),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelledView extends StatelessWidget {
  final VoidCallback? onCamera;
  final VoidCallback onGallery;

  const _CancelledView({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_photography_outlined,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              S.current.menu_vision_cancelled_title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.current.menu_vision_cancelled_subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onCamera != null) ...[
                  FilledButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(S.current.menu_vision_btn_take_photo_short),
                  ),
                  const SizedBox(width: 12),
                ],
                OutlinedButton.icon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library),
                  label: Text(S.current.menu_vision_btn_gallery_short),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
