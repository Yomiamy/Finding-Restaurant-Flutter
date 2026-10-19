import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';

import '../../../domain/entities/entities_barrel.dart';
import '../../../domain/repositories/review_summary_repository.dart';

part 'review_summary_event.dart';
part 'review_summary_state.dart';

/// 管理餐廳 AI 評論情報狀態的 BLoC
class ReviewSummaryBloc extends Bloc<ReviewSummaryEvent, ReviewSummaryState> {
  ReviewSummaryBloc({required ReviewSummaryRepository repository})
    : _repository = repository,
      super(const ReviewSummaryInitial()) {
    on<FetchReviewSummary>(_onFetchReviewSummary);
    on<RetryReviewSummary>(_onRetryReviewSummary);
  }

  final ReviewSummaryRepository _repository;

  RestaurantDetailEntity? _lastDetail;
  List<ReviewDetailEntity>? _lastReviews;

  Future<void> _onFetchReviewSummary(
    FetchReviewSummary event,
    Emitter<ReviewSummaryState> emit,
  ) async {
    _lastDetail = event.detail;
    _lastReviews = event.reviews;

    // 短評為空時即時短路，不耗費 AI 資源
    if (event.reviews.isEmpty) {
      emit(const ReviewSummaryEmpty());
      return;
    }

    emit(const ReviewSummaryLoading());
    try {
      final summary = await _repository.generateReviewSummary(
        detail: event.detail,
        reviews: event.reviews,
      );
      emit(ReviewSummarySuccess(summary: summary));
    } on Exception catch (e, st) {
      Logger().e(
        'ReviewSummaryBloc generation failed',
        error: e,
        stackTrace: st,
      );
      emit(ReviewSummaryFailure(errorMessage: e.toString(), canRetry: true));
    }
  }

  Future<void> _onRetryReviewSummary(
    RetryReviewSummary event,
    Emitter<ReviewSummaryState> emit,
  ) async {
    final detail = _lastDetail;
    final reviews = _lastReviews;
    if (detail == null || reviews == null || reviews.isEmpty) {
      return;
    }

    add(FetchReviewSummary(detail: detail, reviews: reviews));
  }
}
