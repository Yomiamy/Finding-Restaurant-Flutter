import 'package:flutter/material.dart';

import '../../../api/dto/yelp_restaurant_category_dto.dart';
import '../../../features/foundation/style/style_barrel.dart';
import '../../../generated/l10n.dart';

/// 餐飲料理菜系分類 Chip 橫向滾動元件。
///
/// 最多排列 [maxRows] 列（預設 4 列），第一列第一個為「全部」，
/// 第二個為當前被選取的菜系（若有選取）。
class CuisineCategoryChipsWidget extends StatelessWidget {
  const CuisineCategoryChipsWidget({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.maxRows = 4,
  });

  final List<YelpRestaurantCategoryDto> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final hasSelectedCategory =
        selectedCategory != null &&
        selectedCategory!.isNotEmpty &&
        categories.any((c) => c.alias == selectedCategory);

    final List<YelpRestaurantCategoryDto> orderedCuisines;
    if (hasSelectedCategory) {
      orderedCuisines = [
        ...categories.where((c) => c.alias == selectedCategory),
        ...categories.where((c) => c.alias != selectedCategory),
      ];
    } else {
      orderedCuisines = categories;
    }

    final allChips = <Widget>[
      ChoiceChip(
        label: Text(S.current.filter_cuisine_all),
        selected: selectedCategory == null || selectedCategory!.isEmpty,
        onSelected: (selected) {
          if (selected) {
            onCategorySelected(null);
          }
        },
      ),
      ...orderedCuisines.map((category) {
        final isSelected = selectedCategory == category.alias;
        return ChoiceChip(
          label: Text(category.title ?? category.alias ?? ''),
          selected: isSelected,
          onSelected: (selected) {
            onCategorySelected(selected ? category.alias : null);
          },
        );
      }),
    ];

    final rows = List.generate(maxRows, (_) => <Widget>[]);
    for (int i = 0; i < allChips.length; i++) {
      final rowIndex = i == 0 ? 0 : (i - 1) % maxRows;
      rows[rowIndex].add(allChips[i]);
    }

    final activeRows = rows.where((r) => r.isNotEmpty).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int r = 0; r < activeRows.length; r++) ...[
            if (r > 0) const SizedBox(height: ThemeSize.space8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int c = 0; c < activeRows[r].length; c++) ...[
                  if (c > 0) const SizedBox(width: ThemeSize.space8),
                  activeRows[r][c],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
