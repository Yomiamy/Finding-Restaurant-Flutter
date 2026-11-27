import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/domain/repositories/repositories_barrel.dart';
import 'package:flutter_restaruant/features/foundation/style/style_barrel.dart';
import 'package:flutter_restaruant/flow/food_maps/food_maps_barrel.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class _MockFoodMapRepository extends Mock implements FoodMapRepository {}

class _Data {
  static const FoodMapEntity ownedMap = FoodMapEntity(
    id: 'm1',
    title: '台北拉麵地圖',
    description: '深夜必吃',
    ownerUid: 'u1',
    ownerName: 'Alice',
    inviteCode: 'ABCD2345',
    memberUids: ['u1', 'u2'],
    memberNames: {'u1': 'Alice', 'u2': 'Bob'},
    itemCount: 3,
    createdAtMs: 100,
    updatedAtMs: 200,
  );

  static const FoodMapEntity joinedMap = FoodMapEntity(
    id: 'm2',
    title: '好友聚餐',
    description: '',
    ownerUid: 'u2',
    ownerName: 'Bob',
    inviteCode: 'EFGH6789',
    memberUids: ['u2', 'u1'],
    memberNames: {'u2': 'Bob', 'u1': 'Alice'},
    itemCount: 1,
    createdAtMs: 50,
    updatedAtMs: 150,
  );
}

void main() {
  late _MockFoodMapRepository mockRepository;

  setUp(() {
    mockRepository = _MockFoodMapRepository();
    when(() => mockRepository.currentUid).thenReturn('u1');
  });

  Widget buildApp(FoodMapsBloc bloc) {
    return MaterialApp(
      locale: const Locale('zh', 'TW'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      theme: AppThemeData.materialLight,
      routes: {
        FoodMapDetailPage.routeName: (_) =>
            const Scaffold(body: Text('DetailPlaceholder')),
      },
      home: BlocProvider<FoodMapsBloc>.value(
        value: bloc,
        child: const FoodMapsPage(),
      ),
    );
  }

  testWidgets('renders empty state when user has no maps', (tester) async {
    when(() => mockRepository.fetchMyFoodMaps()).thenAnswer((_) async => []);
    final bloc = FoodMapsBloc(
      repository: mockRepository,
      logger: Logger(level: Level.off),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(buildApp(bloc));
    await tester.pumpAndSettle();

    expect(find.text(S.current.food_maps_empty_title), findsOneWidget);
  });

  testWidgets(
    'renders maps, copies invite code, creates, joins, deletes, and leaves',
    (tester) async {
      String? copiedText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copiedText = (call.arguments as Map)['text'] as String?;
            }
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      when(
        () => mockRepository.fetchMyFoodMaps(),
      ).thenAnswer((_) async => const [_Data.ownedMap, _Data.joinedMap]);
      when(
        () => mockRepository.createFoodMap(title: '新地圖', description: '讚'),
      ).thenAnswer(
        (_) async => _Data.ownedMap.copyWith(id: 'm3', title: '新地圖'),
      );
      when(() => mockRepository.joinFoodMapByInviteCode('ZZZZ2345')).thenAnswer(
        (_) async => (
          map: _Data.joinedMap.copyWith(id: 'm4', title: '受邀地圖'),
          alreadyMember: false,
        ),
      );
      when(() => mockRepository.deleteFoodMap('m1')).thenAnswer((_) async {});
      when(() => mockRepository.leaveFoodMap('m2')).thenAnswer((_) async {});

      final bloc = FoodMapsBloc(
        repository: mockRepository,
        logger: Logger(level: Level.off),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(buildApp(bloc));
      await tester.pumpAndSettle();

      expect(find.text('台北拉麵地圖'), findsOneWidget);
      expect(find.text('好友聚餐'), findsOneWidget);
      expect(find.text(S.current.food_maps_owner_badge), findsOneWidget);

      // Copy invite code
      await tester.tap(find.byKey(const Key('food_map_copy_code_m1')));
      await tester.pumpAndSettle();
      expect(copiedText, 'ABCD2345');

      // Create map via FAB
      await tester.tap(find.byKey(const Key('food_maps_create_btn')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('food_maps_create_title_field')),
        '新地圖',
      );
      await tester.enterText(
        find.byKey(const Key('food_maps_create_desc_field')),
        '讚',
      );
      await tester.tap(find.byKey(const Key('food_maps_create_submit_btn')));
      await tester.pumpAndSettle();
      expect(find.text('新地圖'), findsOneWidget);

      // Join map via AppBar button
      await tester.tap(find.byKey(const Key('food_maps_join_btn')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('food_maps_join_code_field')),
        'ZZZZ2345',
      );
      await tester.tap(find.byKey(const Key('food_maps_join_submit_btn')));
      await tester.pumpAndSettle();
      expect(find.text('受邀地圖'), findsOneWidget);

      // Delete owned map
      await tester.tap(find.byKey(const Key('food_map_action_m1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('food_maps_confirm_delete_btn')));
      await tester.pumpAndSettle();
      verify(() => mockRepository.deleteFoodMap('m1')).called(1);

      // Leave joined map
      await tester.tap(find.byKey(const Key('food_map_action_m2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('food_maps_confirm_leave_btn')));
      await tester.pumpAndSettle();
      verify(() => mockRepository.leaveFoodMap('m2')).called(1);
    },
  );
}
