#!/bin/bash
# add to zh_TW
sed -i '' -e 's/}/  ,"ai_foodie_error_load_suggestions": "載入建議時發生錯誤：{error}",\n  "ai_foodie_error_connect_assistant": "連線助理時發生錯誤：{error}",\n  "a2ui_error_unknown_component": "無法識別的 GenUI 元件結構",\n  "a2ui_dish_catalog_empty": "菜單資料為空",\n  "a2ui_comparison_matrix_title": "推薦餐廳對比",\n  "a2ui_comparison_item_name": "精選餐廳",\n  "a2ui_action_chip_group_title": "快捷操作選項"\n}/' lib/l10n/intl_zh_TW.arb

# add to en
sed -i '' -e 's/}/  ,"ai_foodie_error_load_suggestions": "Error loading suggestions: {error}",\n  "ai_foodie_error_connect_assistant": "Error connecting to assistant: {error}",\n  "a2ui_error_unknown_component": "Unrecognized GenUI component structure",\n  "a2ui_dish_catalog_empty": "Menu data is empty",\n  "a2ui_comparison_matrix_title": "Recommended Restaurant Comparison",\n  "a2ui_comparison_item_name": "Selected Restaurant",\n  "a2ui_action_chip_group_title": "Quick Actions"\n}/' lib/l10n/intl_en.arb
