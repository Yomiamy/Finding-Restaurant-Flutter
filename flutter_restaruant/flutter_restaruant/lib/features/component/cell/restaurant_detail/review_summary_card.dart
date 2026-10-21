import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../domain/entities/entities_barrel.dart';
import '../../../../domain/repositories/review_summary_repository.dart';
import '../../../../flow/restaurant/bloc/review_summary_bloc.dart';
import '../../../../generated/l10n.dart';
import '../../../foundation/style/style_barrel.dart';
import 'review_summary_skeleton.dart';

/// 餐廳 AI 評論智慧摘要情報卡片
class ReviewSummaryCard extends StatefulWidget {
  const ReviewSummaryCard({
    super.key = const Key('ReviewSummaryCard'),
    required this.detail,
    required this.reviews,
    this.bloc,
  });

  final RestaurantDetailEntity detail;
  final List<ReviewDetailEntity> reviews;
  final ReviewSummaryBloc? bloc;

  @override
  State<ReviewSummaryCard> createState() => _ReviewSummaryCardState();
}

class _ReviewSummaryCardState extends State<ReviewSummaryCard> {
  late ReviewSummaryBloc _bloc;
  late bool _isLocalBloc;

  @override
  void initState() {
    super.initState();
    if (widget.bloc != null) {
      _bloc = widget.bloc!;
      _isLocalBloc = false;
    } else {
      _bloc = ReviewSummaryBloc(repository: GetIt.I<ReviewSummaryRepository>());
      _isLocalBloc = true;
    }

    if (widget.reviews.isNotEmpty) {
      _bloc.add(
        FetchReviewSummary(detail: widget.detail, reviews: widget.reviews),
      );
    }
  }

  @override
  void didUpdateWidget(covariant ReviewSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.name != widget.detail.name ||
        oldWidget.reviews != widget.reviews) {
      if (widget.reviews.isNotEmpty) {
        _bloc.add(
          FetchReviewSummary(detail: widget.detail, reviews: widget.reviews),
        );
      }
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
    return BlocBuilder<ReviewSummaryBloc, ReviewSummaryState>(
      bloc: _bloc,
      builder: (context, state) {
        return switch (state) {
          ReviewSummaryInitial() ||
          ReviewSummaryEmpty() => const SizedBox.shrink(),
          ReviewSummaryLoading() => const ReviewSummarySkeleton(),
          ReviewSummaryFailure(:final canRetry) => _buildFailureView(
            context,
            canRetry: canRetry,
          ),
          ReviewSummarySuccess(:final summary) => _buildSuccessView(
            context,
            summary,
          ),
        };
      },
    );
  }

  Widget _buildFailureView(BuildContext context, {required bool canRetry}) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: ThemeSize.space12,
        vertical: ThemeSize.space8,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeSize.space12,
        vertical: ThemeSize.space10,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(ThemeSize.radius12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.error,
            size: ThemeSize.size20,
          ),
          const SizedBox(width: ThemeSize.space8),
          Expanded(
            child: Text(
              S.current.review_summary_failed,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          if (canRetry)
            TextButton.icon(
              key: const Key('ReviewSummaryRetryButton'),
              onPressed: () => _bloc.add(const RetryReviewSummary()),
              icon: const Icon(Icons.refresh, size: ThemeSize.size16),
              label: Text(S.current.review_summary_retry),
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, ReviewSummaryEntity summary) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: ThemeSize.space12,
        vertical: ThemeSize.space8,
      ),
      padding: const EdgeInsets.all(ThemeSize.space12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ThemeSize.radius12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 頂部標題列
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: colorScheme.primary,
                size: ThemeSize.size18,
              ),
              const SizedBox(width: ThemeSize.space8),
              Text(
                S.current.review_summary_title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ThemeSize.space8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(ThemeSize.radius12),
                ),
                child: Text(
                  'Gemini AI',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (summary.summary.isNotEmpty) ...[
            const SizedBox(height: ThemeSize.space8),
            Text(
              summary.summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
          if (summary.pros.isNotEmpty || summary.cons.isNotEmpty)
            const SizedBox(height: ThemeSize.space10),
          // 值得一試 (Pros)
          if (summary.pros.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: ThemeSize.size16,
                ),
                const SizedBox(width: ThemeSize.space8),
                Text(
                  S.current.review_summary_pros,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ThemeSize.space4),
            Padding(
              padding: const EdgeInsets.only(left: ThemeSize.space12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: summary.pros
                    .map(
                      (pro) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          '• $pro',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          // 注意事項 (Cons)
          if (summary.cons.isNotEmpty) ...[
            const SizedBox(height: ThemeSize.space8),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber.shade800,
                  size: ThemeSize.size16,
                ),
                const SizedBox(width: ThemeSize.space8),
                Text(
                  S.current.review_summary_cons,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ThemeSize.space4),
            Padding(
              padding: const EdgeInsets.only(left: ThemeSize.space12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: summary.cons
                    .map(
                      (con) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          '• $con',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          // 招牌推薦 (Highlights)
          if (summary.highlights.isNotEmpty) ...[
            const SizedBox(height: ThemeSize.space10),
            Row(
              children: [
                Icon(
                  Icons.star_outline_rounded,
                  color: colorScheme.primary,
                  size: ThemeSize.size16,
                ),
                const SizedBox(width: ThemeSize.space8),
                Text(
                  S.current.review_summary_highlights,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ThemeSize.space8),
            Wrap(
              spacing: ThemeSize.space8,
              runSpacing: ThemeSize.space5,
              children: summary.highlights.map((dish) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ThemeSize.space8,
                    vertical: ThemeSize.space4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(ThemeSize.radius8),
                  ),
                  child: Text(
                    dish,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
