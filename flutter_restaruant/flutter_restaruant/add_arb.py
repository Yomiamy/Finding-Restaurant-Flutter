import json

def add_keys(file_path, keys):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    data.update(keys)
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

add_keys('lib/l10n/intl_zh_TW.arb', {
  "ai_foodie_error_load_suggestions": "載入建議時發生錯誤：{error}",
  "ai_foodie_error_connect_assistant": "連線助理時發生錯誤：{error}",
  "a2ui_error_unknown_component": "無法識別的 GenUI 元件結構",
  "a2ui_dish_catalog_empty": "菜單資料為空",
  "a2ui_comparison_matrix_title": "推薦餐廳對比",
  "a2ui_comparison_item_name": "精選餐廳",
  "a2ui_action_chip_group_title": "快捷操作選項"
})

add_keys('lib/l10n/intl_en.arb', {
  "ai_foodie_error_load_suggestions": "Error loading suggestions: {error}",
  "ai_foodie_error_connect_assistant": "Error connecting to assistant: {error}",
  "a2ui_error_unknown_component": "Unrecognized GenUI component structure",
  "a2ui_dish_catalog_empty": "Menu data is empty",
  "a2ui_comparison_matrix_title": "Recommended Restaurant Comparison",
  "a2ui_comparison_item_name": "Selected Restaurant",
  "a2ui_action_chip_group_title": "Quick Actions"
})
