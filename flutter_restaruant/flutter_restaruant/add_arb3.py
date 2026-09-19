import json

def add_keys(file_path, keys):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    data.update(keys)
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

add_keys('lib/l10n/intl_zh_TW.arb', {
  "menu_vision_error_analyze_failed": "菜單辨識失敗：{error}",
  "menu_vision_error_retry_failed": "重試分析失敗：{error}"
})

add_keys('lib/l10n/intl_en.arb', {
  "menu_vision_error_analyze_failed": "Menu recognition failed: {error}",
  "menu_vision_error_retry_failed": "Retry analysis failed: {error}"
})
