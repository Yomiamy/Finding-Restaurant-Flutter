part of 'review_summary_bloc.dart';

@immutable
sealed class ReviewSummaryState extends Equatable {
  const ReviewSummaryState();

  @override
  List<Object?> get props => [];
}

final class ReviewSummaryInitial extends ReviewSummaryState {
  const ReviewSummaryInitial();
}

final class ReviewSummaryLoading extends ReviewSummaryState {
  const ReviewSummaryLoading();
}

final class ReviewSummaryEmpty extends ReviewSummaryState {
  const ReviewSummaryEmpty();
}

final class ReviewSummarySuccess extends ReviewSummaryState {
  const ReviewSummarySuccess({required this.summary});

  final ReviewSummaryEntity summary;

  @override
  List<Object?> get props => [summary];
}

final class ReviewSummaryFailure extends ReviewSummaryState {
  const ReviewSummaryFailure({
    required this.errorMessage,
    this.canRetry = true,
  });

  final String errorMessage;
  final bool canRetry;

  @override
  List<Object?> get props => [errorMessage, canRetry];
}
