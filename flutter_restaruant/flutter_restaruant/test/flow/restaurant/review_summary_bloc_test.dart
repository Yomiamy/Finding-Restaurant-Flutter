import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/review_summary_repository.dart';
import 'package:flutter_restaruant/flow/restaurant/bloc/review_summary_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockReviewSummaryRepository extends Mock
    implements ReviewSummaryRepository {}

void main() {
  late _MockReviewSummaryRepository repository;

  const sampleDetail = RestaurantDetailEntity(
    name: '築地鮮魚',
    rating: 4.5,
    reviewCount: 88,
  );

  const sampleReviews = [
    ReviewDetailEntity(
      id: 'r1',
      rating: 5,
      text: '海鮮井用料實在，醋飯調味非常剛好！',
      user: ReviewerEntity(name: 'Charlie'),
    ),
  ];

  const sampleSummary = ReviewSummaryEntity(
    pros: ['用料實在', '調味極佳'],
    cons: ['位子較少'],
    highlights: ['招牌海鮮丼'],
    summary: '高 CP 值的美味丼飯。',
  );

  setUpAll(() {
    registerFallbackValue(const RestaurantDetailEntity());
    registerFallbackValue(<ReviewDetailEntity>[]);
  });

  setUp(() {
    repository = _MockReviewSummaryRepository();
  });

  group('ReviewSummaryBloc Tests', () {
    test('初始狀態為 ReviewSummaryInitial', () {
      final bloc = ReviewSummaryBloc(repository: repository);
      expect(bloc.state, equals(const ReviewSummaryInitial()));
      bloc.close();
    });

    blocTest<ReviewSummaryBloc, ReviewSummaryState>(
      '當評論列表為空時短路發射 ReviewSummaryEmpty，不調用 repository',
      build: () => ReviewSummaryBloc(repository: repository),
      act: (bloc) =>
          bloc.add(const FetchReviewSummary(detail: sampleDetail, reviews: [])),
      expect: () => [const ReviewSummaryEmpty()],
      verify: (_) {
        verifyNever(
          () => repository.generateReviewSummary(
            detail: any(named: 'detail'),
            reviews: any(named: 'reviews'),
          ),
        );
      },
    );

    blocTest<ReviewSummaryBloc, ReviewSummaryState>(
      '正常獲取評論情報時，依序發射 Loading 與 Success',
      build: () {
        when(
          () => repository.generateReviewSummary(
            detail: any(named: 'detail'),
            reviews: any(named: 'reviews'),
          ),
        ).thenAnswer((_) async => sampleSummary);
        return ReviewSummaryBloc(repository: repository);
      },
      act: (bloc) => bloc.add(
        const FetchReviewSummary(detail: sampleDetail, reviews: sampleReviews),
      ),
      expect: () => [
        const ReviewSummaryLoading(),
        const ReviewSummarySuccess(summary: sampleSummary),
      ],
      verify: (_) {
        verify(
          () => repository.generateReviewSummary(
            detail: any(named: 'detail'),
            reviews: any(named: 'reviews'),
          ),
        ).called(1);
      },
    );

    blocTest<ReviewSummaryBloc, ReviewSummaryState>(
      '當 Repository 拋出例外時，發射 Loading 與 Failure(canRetry: true)',
      build: () {
        when(
          () => repository.generateReviewSummary(
            detail: any(named: 'detail'),
            reviews: any(named: 'reviews'),
          ),
        ).thenThrow(Exception('Network timeout'));
        return ReviewSummaryBloc(repository: repository);
      },
      act: (bloc) => bloc.add(
        const FetchReviewSummary(detail: sampleDetail, reviews: sampleReviews),
      ),
      expect: () => [
        const ReviewSummaryLoading(),
        isA<ReviewSummaryFailure>()
            .having((s) => s.canRetry, 'canRetry', isTrue)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('Network timeout'),
            ),
      ],
    );

    blocTest<ReviewSummaryBloc, ReviewSummaryState>(
      '失敗後呼叫 RetryReviewSummary 能使用快取參數重試成功',
      build: () {
        var callCount = 0;
        when(
          () => repository.generateReviewSummary(
            detail: any(named: 'detail'),
            reviews: any(named: 'reviews'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            throw Exception('Gemini 429 quota');
          }
          return sampleSummary;
        });
        return ReviewSummaryBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(
          const FetchReviewSummary(
            detail: sampleDetail,
            reviews: sampleReviews,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const RetryReviewSummary());
      },
      expect: () => [
        const ReviewSummaryLoading(),
        isA<ReviewSummaryFailure>(),
        const ReviewSummaryLoading(),
        const ReviewSummarySuccess(summary: sampleSummary),
      ],
      verify: (_) {
        verify(
          () => repository.generateReviewSummary(
            detail: any(named: 'detail'),
            reviews: any(named: 'reviews'),
          ),
        ).called(2);
      },
    );

    blocTest<ReviewSummaryBloc, ReviewSummaryState>(
      '若尚未請求過即呼叫 RetryReviewSummary，不發射任何狀態',
      build: () => ReviewSummaryBloc(repository: repository),
      act: (bloc) => bloc.add(const RetryReviewSummary()),
      expect: () => <ReviewSummaryState>[],
      verify: (_) {
        verifyNever(
          () => repository.generateReviewSummary(
            detail: any(named: 'detail'),
            reviews: any(named: 'reviews'),
          ),
        );
      },
    );
  });
}
