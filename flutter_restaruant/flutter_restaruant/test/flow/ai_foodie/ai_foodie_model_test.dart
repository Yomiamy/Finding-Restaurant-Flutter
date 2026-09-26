import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/flow/ai_foodie/model/ai_foodie_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiFoodieMessageModel.fromEntity', () {
    test('全缺值 → UI 預設值', () {
      final m = AiFoodieMessageModel.fromEntity(
        AiFoodieMessage.fromJson(const {}),
      );
      expect(m.isUser, isFalse);
      expect(m.text, '');
      expect(m.components, isEmpty);
    });

    test('全有值 → 原值', () {
      final entity = AiFoodieMessage.fromJson(const {
        'id': 'm1',
        'is_user': true,
        'text': '推薦如下',
        'components': [],
      });
      final m = AiFoodieMessageModel.fromEntity(entity);
      expect(m.isUser, isTrue);
      expect(m.text, '推薦如下');
    });
  });

  group('A2UIComponentModel.fromEntity', () {
    test('DishCatalogComponent → null（AI 覓食畫布不渲染）', () {
      const entity = DishCatalogComponent(dishes: []);
      expect(A2UIComponentModel.fromEntity(entity), isNull);
    });

    test('FallbackMarkdownComponent → FallbackTextModel', () {
      const entity = FallbackMarkdownComponent(text: '降級');
      expect(
        A2UIComponentModel.fromEntity(entity),
        const FallbackTextModel(text: '降級'),
      );
    });
  });

  group('ComparisonMatrixModel.fromEntity', () {
    test('全缺值 → UI 預設值', () {
      final entity = ComparisonMatrixComponent(
        title: S.current.a2ui_comparison_matrix_title,
        items: const [],
      );
      final m = ComparisonMatrixModel.fromEntity(entity);
      expect(m.title, S.current.a2ui_comparison_matrix_title);
      expect(m.items, isEmpty);
    });

    test('全有值 → 原值', () {
      const item = RestaurantComparisonItem(
        id: 'r1',
        name: '野武士',
        rating: 4.0,
        price: '\$550',
        highlights: ['串燒'],
        address: '台北市中山區',
        category: '日式',
        imageUrl: 'https://img/1.jpg',
      );
      const entity = ComparisonMatrixComponent(title: '精選對比', items: [item]);
      final m = ComparisonMatrixModel.fromEntity(entity);
      expect(m.title, '精選對比');
      expect(
        m.items.single,
        const ComparisonItemModel(
          id: 'r1',
          name: '野武士',
          rating: 4.0,
          price: '\$550',
          highlights: ['串燒'],
          address: '台北市中山區',
          category: '日式',
          imageUrl: 'https://img/1.jpg',
        ),
      );
    });

    test('item 缺值 price／address／category／imageUrl 維持 null（刻意 nullable）', () {
      const item = RestaurantComparisonItem(id: '', name: 'A', rating: 0.0);
      final m = ComparisonItemModel.fromEntity(item);
      expect(m.price, isNull);
      expect(m.address, isNull);
      expect(m.category, isNull);
      expect(m.imageUrl, isNull);
    });
  });

  group('ActionChipGroupModel.fromEntity', () {
    test('chip 轉換', () {
      const entity = ActionChipGroupComponent(
        chips: [
          ActionChipItem(label: 'L', action: 'query', payload: {'prompt': 'p'}),
        ],
      );
      final m = ActionChipGroupModel.fromEntity(entity);
      expect(
        m.chips.single,
        const ActionChipModel(
          label: 'L',
          action: 'query',
          payload: {'prompt': 'p'},
        ),
      );
    });
  });

  group('DecisionRouletteModel.fromEntity', () {
    test('全缺值 → UI 預設值', () {
      final entity = DecisionRouletteComponent(
        title: S.current.ai_foodie_roulette_default_title,
        options: const [],
      );
      final m = DecisionRouletteModel.fromEntity(entity);
      expect(m.title, S.current.ai_foodie_roulette_default_title);
      expect(m.options, isEmpty);
    });

    test('全有值 → 原值', () {
      const entity = DecisionRouletteComponent(
        title: '今晚吃啥',
        options: ['A', 'B'],
      );
      final m = DecisionRouletteModel.fromEntity(entity);
      expect(m.title, '今晚吃啥');
      expect(m.options, ['A', 'B']);
    });
  });

  group('UI model 預設值（entity 全 null）', () {
    test('AI 覓食元件', () {
      expect(
        ComparisonMatrixModel.fromEntity(const ComparisonMatrixComponent()),
        ComparisonMatrixModel(
          title: S.current.a2ui_comparison_matrix_title,
          items: const [],
        ),
      );
      expect(
        ComparisonItemModel.fromEntity(const RestaurantComparisonItem()),
        ComparisonItemModel(
          id: '',
          name: S.current.a2ui_comparison_item_name,
          rating: 0.0,
          highlights: const [],
        ),
      );
      expect(
        ActionChipGroupModel.fromEntity(const ActionChipGroupComponent()),
        const ActionChipGroupModel(chips: []),
      );
      expect(
        ActionChipModel.fromEntity(const ActionChipItem()),
        const ActionChipModel(label: '', action: '', payload: {}),
      );
      expect(
        DecisionRouletteModel.fromEntity(const DecisionRouletteComponent()),
        DecisionRouletteModel(
          title: S.current.ai_foodie_roulette_default_title,
          options: const [],
        ),
      );
      expect(
        A2UIComponentModel.fromEntity(const FallbackMarkdownComponent()),
        const FallbackTextModel(text: ''),
      );
    });

    test('AiFoodieMessage', () {
      expect(
        AiFoodieMessageModel.fromEntity(AiFoodieMessage.fromJson(const {})),
        const AiFoodieMessageModel(isUser: false, text: '', components: []),
      );
    });
  });
}
