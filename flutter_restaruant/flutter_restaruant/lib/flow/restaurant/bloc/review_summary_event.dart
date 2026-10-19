part of 'review_summary_bloc.dart';

@immutable
sealed class ReviewSummaryEvent extends Equatable {
  const ReviewSummaryEvent();

  @override
  List<Object?> get props => [];
}

final class FetchReviewSummary extends ReviewSummaryEvent {
  const FetchReviewSummary({required this.detail, required this.reviews});

  final RestaurantDetailEntity detail;
  final List<ReviewDetailEntity> reviews;

  @override
  List<Object?> get props => [detail, reviews];
}

final class RetryReviewSummary extends ReviewSummaryEvent {
  const RetryReviewSummary();
}
