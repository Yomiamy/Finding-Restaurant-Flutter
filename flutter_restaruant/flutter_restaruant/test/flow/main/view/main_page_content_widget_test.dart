import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_restaruant/component/component_barrel.dart';
import 'package:flutter_restaruant/flow/main/bloc/bloc_barrel.dart';
import 'package:flutter_restaruant/flow/main/view/view_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_restaruant/model/model_barrel.dart';

class _FakeMainBloc extends Bloc<MainEvent, MainState> implements MainBloc {
  _FakeMainBloc([super.initialState = const MainInitial()]);
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
}
