import 'package:flutter/material.dart';
import 'package:flutter_restaruant/flow/ai_foodie/model/ai_foodie_model.dart';
import 'package:flutter_restaruant/flow/ai_foodie/view/comparison_matrix_card.dart';
import 'package:flutter_test/flutter_test.dart';

class _Data {
  static const String longTitle = '這是一段由模型產生而且非常非常非常長的多店對比標題文字內容';
  static const String longCategory = '日式料理居酒屋燒肉串燒丼飯拉麵';
  static const String longPrice = r'$550 - $1,200 per person';

  static ComparisonMatrixModel matrix({
    required String category,
    required String price,
  }) {
    return ComparisonMatrixModel(
      title: longTitle,
      items: [
        ComparisonItemModel(
          id: '1',
          name: 'Restaurant',
          rating: 4.5,
          category: category,
          price: price,
          highlights: const ['Quiet', 'Parking'],
          address: 'Taipei',
        ),
      ],
    );
  }
}

Future<void> _pumpCard(WidgetTester tester, ComparisonMatrixModel model) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: ComparisonMatrixCard(component: model),
        ),
      ),
    ),
  );
}

void main() {
  group('ComparisonMatrixCard', () {
    testWidgets('長標題、長類別與長價格不會 overflow', (tester) async {
      await _pumpCard(
        tester,
        _Data.matrix(category: _Data.longCategory, price: _Data.longPrice),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
