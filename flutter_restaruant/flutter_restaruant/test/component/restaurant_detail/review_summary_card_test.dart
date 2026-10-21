import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/features/component/cell/restaurant_detail/restaurant_detail_barrel.dart';
import 'package:flutter_restaruant/flow/restaurant/bloc/review_summary_bloc.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockReviewSummaryBloc
    extends MockBloc<ReviewSummaryEvent, ReviewSummaryState>
    implements ReviewSummaryBloc {}

void main() {
  late _MockReviewSummaryBloc bloc;

  const sampleDetail = RestaurantDetailEntity(
    name: '極味壽司',
    rating: 4.8,
    reviewCount: 100,
  );

  const sampleReviews = [
    ReviewDetailEntity(
      id: 'r1',
      rating: 5,
      text: '海膽很甜！',
      user: ReviewerEntity(name: 'Alice'),
    ),
  ];

  setUpAll(() async {
    await S.load(const Locale('zh', 'TW'));
  });

  setUp(() {
    bloc = _MockReviewSummaryBloc();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: const Locale('zh', 'TW'),
      home: Scaffold(
        body: ReviewSummaryCard(
          detail: sampleDetail,
          reviews: sampleReviews,
          bloc: bloc,
        ),
      ),
    );
  }

  group('ReviewSummaryCard Widget Tests', () {
    testWidgets('ReviewSummaryEmpty 狀態時不渲染任何卡片內容', (tester) async {
      when(() => bloc.state).thenReturn(const ReviewSummaryEmpty());

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(ReviewSummarySkeleton), findsNothing);
      expect(find.text('AI 評論情報'), findsNothing);
    });

    testWidgets('ReviewSummaryLoading 狀態時渲染骨架屏', (tester) async {
      when(() => bloc.state).thenReturn(const ReviewSummaryLoading());

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(ReviewSummarySkeleton), findsOneWidget);
    });

    testWidgets('ReviewSummarySuccess 狀態時完整渲染情報標題、總結、Pros、Cons 與 Highlights', (
      tester,
    ) async {
      const summary = ReviewSummaryEntity(
        pros: ['新鮮度極佳', '服務親切'],
        cons: ['座位偏少'],
        highlights: ['招牌海膽', '干貝握壽司'],
        summary: 'CP 值極高的割烹餐廳。',
      );
      when(
        () => bloc.state,
      ).thenReturn(const ReviewSummarySuccess(summary: summary));

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('AI 評論情報'), findsOneWidget);
      expect(find.text('Gemini AI'), findsOneWidget);
      expect(find.text('CP 值極高的割烹餐廳。'), findsOneWidget);
      expect(find.text('值得一試'), findsOneWidget);
      expect(find.text('• 新鮮度極佳'), findsOneWidget);
      expect(find.text('• 服務親切'), findsOneWidget);
      expect(find.text('注意事項'), findsOneWidget);
      expect(find.text('• 座位偏少'), findsOneWidget);
      expect(find.text('招牌推薦'), findsOneWidget);
      expect(find.text('招牌海膽'), findsOneWidget);
      expect(find.text('干貝握壽司'), findsOneWidget);
    });

    testWidgets(
      'ReviewSummaryFailure 狀態時渲染重試提示與按鈕，點擊後觸發 RetryReviewSummary 事件',
      (tester) async {
        when(() => bloc.state).thenReturn(
          const ReviewSummaryFailure(
            errorMessage: 'Timeout error',
            canRetry: true,
          ),
        );

        await tester.pumpWidget(buildTestWidget());

        expect(find.text('AI 評論情報暫時無法取得'), findsOneWidget);
        final retryButtonFinder = find.byKey(
          const Key('ReviewSummaryRetryButton'),
        );
        expect(retryButtonFinder, findsOneWidget);

        await tester.tap(retryButtonFinder);
        await tester.pump();

        verify(() => bloc.add(const RetryReviewSummary())).called(1);
      },
    );
  });
}
