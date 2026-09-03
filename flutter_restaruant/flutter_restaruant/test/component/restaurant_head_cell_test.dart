import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_restaruant/component/cell/restaurant_detail/restaurant_head_cell.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/flow/restaurant/bloc/bloc_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRestaurantDetailRepository implements RestaurantDetailRepository {
  RestaurantEntity? lastToggled;

  @override
  Future<RestaurantDetailEntity> fetchYelpRestaurantDetailInfo(
    String id,
  ) async => const RestaurantDetailEntity(name: 'Test Detail');

  @override
  Future<ReviewEntity> fetchYelpRestaurantReviewInfo(String id) async =>
      const ReviewEntity(reviews: [], total: 0);

  @override
  Future<RestaurantEntity> toggleFavor(RestaurantEntity summaryInfo) async {
    lastToggled = summaryInfo;
    return summaryInfo.copyWith(favor: !summaryInfo.favor);
  }
}

void main() {
  group('RestaurantHeadCell Widget Tests', () {
    late _FakeRestaurantDetailRepository fakeRepo;
    late RestaurantDetailBloc bloc;

    setUp(() {
      fakeRepo = _FakeRestaurantDetailRepository();
      bloc = RestaurantDetailBloc(repository: fakeRepo);
    });

    tearDown(() {
      bloc.close();
    });

    testWidgets('已收藏時顯示紅色的 Icons.favorite 向量圖示', (tester) async {
      const restaurant = RestaurantEntity(
        id: 'favor_1',
        name: 'Favor Rest',
        favor: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeData.materialLight,
          localizationsDelegates: const [S.delegate],
          home: BlocProvider<RestaurantDetailBloc>.value(
            value: bloc,
            child: const Scaffold(
              body: RestaurantHeadCell(imageUrl: '', summaryInfo: restaurant),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.favorite));
      expect(iconWidget.color, ThemeColor.colorf44336);
    });

    testWidgets('未收藏時顯示 Icons.favorite_border 且點擊觸發 ToggleFavor', (
      tester,
    ) async {
      const restaurant = RestaurantEntity(
        id: 'unfavor_1',
        name: 'Unfavor Rest',
        favor: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeData.materialLight,
          localizationsDelegates: const [S.delegate],
          home: BlocProvider<RestaurantDetailBloc>.value(
            value: bloc,
            child: const Scaffold(
              body: RestaurantHeadCell(imageUrl: '', summaryInfo: restaurant),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(fakeRepo.lastToggled?.id, 'unfavor_1');
    });
  });
}
