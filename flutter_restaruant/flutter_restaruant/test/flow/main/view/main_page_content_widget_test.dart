import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/features/component/component_barrel.dart';
import 'package:flutter_restaruant/flow/main/bloc/bloc_barrel.dart';
import 'package:flutter_restaruant/flow/main/view/view_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_restaruant/models/model_barrel.dart';

class _FakeMainBloc extends Bloc<MainEvent, MainState> implements MainBloc {
  _FakeMainBloc([super.initialState = const MainInitial()]);
}

class _ResetTestMainBloc extends Bloc<MainEvent, MainState> implements MainBloc {
  _ResetTestMainBloc() : super(const MainInitial()) {
    on<MainEvent>((_, __) {});
  }

  final List<MainEvent> dispatched = [];

  @override
  void onEvent(MainEvent event) {
    super.onEvent(event);
    dispatched.add(event);
  }
}

void main() {
  testWidgets(
    'MainPageContentWidget renders skeletons when state is MainInitial and list mode',
    (WidgetTester tester) async {
      final bloc = _FakeMainBloc(const MainInitial());

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.delegate.supportedLocales,
          home: BlocProvider<MainBloc>.value(
            value: bloc,
            child: Scaffold(
              body: MainPageContentWidget(
                filterConfigs: FilterConfigs(),
                isListMode: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RestaurantItemSkeleton), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      await bloc.close();
    },
  );

  testWidgets(
    'MainPageContentWidget renders LoadingWidget when state is MainInitial and map mode',
    (WidgetTester tester) async {
      final bloc = _FakeMainBloc(const MainInitial());

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.delegate.supportedLocales,
          home: BlocProvider<MainBloc>.value(
            value: bloc,
            child: Scaffold(
              body: MainPageContentWidget(
                filterConfigs: FilterConfigs(),
                isListMode: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LoadingWidget), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await bloc.close();
    },
  );

  testWidgets(
    'MainPageContentWidget renders EmptyDataWidget when summaryInfos is empty',
    (WidgetTester tester) async {
      final bloc = _FakeMainBloc(const Success(summaryInfos: []));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.delegate.supportedLocales,
          home: BlocProvider<MainBloc>.value(
            value: bloc,
            child: Scaffold(
              body: MainPageContentWidget(
                filterConfigs: FilterConfigs(),
                isListMode: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(EmptyDataWidget), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await bloc.close();
    },
  );

  testWidgets(
    'MainPageContentWidget clears old results and renders error when state is Failure',
    (WidgetTester tester) async {
      final bloc = _FakeMainBloc(
        const Success(
          summaryInfos: [
            RestaurantEntity(id: '1', name: 'Old Restaurant'),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.delegate.supportedLocales,
          home: BlocProvider<MainBloc>.value(
            value: bloc,
            child: Scaffold(
              body: MainPageContentWidget(
                filterConfigs: FilterConfigs(),
                isListMode: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Old Restaurant'), findsOneWidget);

      bloc.emit(const Failure());
      await tester.pump();

      expect(find.text('Old Restaurant'), findsNothing);
      expect(find.byType(EmptyDataWidget), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await bloc.close();
    },
  );

  testWidgets(
    'MainPageContentWidget preserves existing list when Failure occurs during LoadMore',
    (WidgetTester tester) async {
      final bloc = _FakeMainBloc(
        const Success(
          summaryInfos: [
            RestaurantEntity(id: '1', name: 'Existing Restaurant'),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.delegate.supportedLocales,
          home: BlocProvider<MainBloc>.value(
            value: bloc,
            child: Scaffold(
              body: MainPageContentWidget(
                filterConfigs: FilterConfigs(),
                isListMode: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Existing Restaurant'), findsOneWidget);

      // 觸發載入更多
      bloc.emit(
        const LoadMoreInProgress(
          summaryInfos: [
            RestaurantEntity(id: '1', name: 'Existing Restaurant'),
          ],
        ),
      );
      await tester.pump();
      expect(find.text('Existing Restaurant'), findsOneWidget);

      // 分頁請求失敗
      bloc.emit(const Failure());
      await tester.pump();

      // 原本已載入之餐廳仍應保留於畫面上，不變為全空錯誤畫面
      expect(find.text('Existing Restaurant'), findsOneWidget);
      expect(find.byType(EmptyDataWidget), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await bloc.close();
    },
  );

  testWidgets(
    'MainPageContentWidget forwards all filter configs on ResetSuccess',
    (WidgetTester tester) async {
      final bloc = _ResetTestMainBloc();
      addTearDown(bloc.close);
      final configs = FilterConfigs(
        price: '2',
        openAt: 12345000,
        sortBy: 'best_match',
        categories: 'japanese',
        radius: 3000,
        openNow: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.delegate.supportedLocales,
          home: BlocProvider<MainBloc>.value(
            value: bloc,
            child: Scaffold(
              body: MainPageContentWidget(
                filterConfigs: configs,
                isListMode: true,
              ),
            ),
          ),
        ),
      );

      bloc.emit(const ResetSuccess());
      await tester.pump();

      expect(
        bloc.dispatched.whereType<FetchSearchInfo>().any(
              (e) =>
                  e.price == '2' &&
                  e.openAt == 12345 &&
                  e.sortBy == 'best_match' &&
                  e.categories == 'japanese' &&
                  e.radius == 3000 &&
                  e.openNow == true,
            ),
        isTrue,
      );

      await tester.pumpWidget(const SizedBox());
    },
  );
}
