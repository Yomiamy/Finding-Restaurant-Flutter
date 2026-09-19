import 'package:logger/logger.dart';
import '../../generated/l10n.dart';

abstract class A2UIFallbackStrings {
  static String get unknownComponent {
    try {
      return S.current.a2ui_error_unknown_component;
    } catch (e) {
      Logger().d(
        '[A2UIFallbackStrings] i18n delegate not initialized, using fallback.',
        error: e,
      );
      return '無法識別的 GenUI 元件結構';
    }
  }

  static String get dishCatalogEmpty {
    try {
      return S.current.a2ui_dish_catalog_empty;
    } catch (e) {
      Logger().d(
        '[A2UIFallbackStrings] i18n delegate not initialized, using fallback.',
        error: e,
      );
      return '菜單資料為空';
    }
  }

  static String get comparisonMatrixTitle {
    try {
      return S.current.a2ui_comparison_matrix_title;
    } catch (e) {
      Logger().d(
        '[A2UIFallbackStrings] i18n delegate not initialized, using fallback.',
        error: e,
      );
      return '推薦餐廳對比';
    }
  }

  static String get comparisonItemName {
    try {
      return S.current.a2ui_comparison_item_name;
    } catch (e) {
      Logger().d(
        '[A2UIFallbackStrings] i18n delegate not initialized, using fallback.',
        error: e,
      );
      return '精選餐廳';
    }
  }

  static String get actionChipGroupTitle {
    try {
      return S.current.a2ui_action_chip_group_title;
    } catch (e) {
      Logger().d(
        '[A2UIFallbackStrings] i18n delegate not initialized, using fallback.',
        error: e,
      );
      return '快捷操作選項';
    }
  }

  static String get decisionRouletteTitle {
    try {
      return S.current.ai_foodie_roulette_default_title;
    } catch (e) {
      Logger().d(
        '[A2UIFallbackStrings] i18n delegate not initialized, using fallback.',
        error: e,
      );
      return '今晚吃什麼？命運大轉盤';
    }
  }
}
