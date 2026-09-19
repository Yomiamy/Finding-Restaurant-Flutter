import json

def add_keys(file_path, keys):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    data.update(keys)
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

add_keys('lib/l10n/intl_zh_TW.arb', {
  "menu_vision_error_unexpected_format": "未預期的組件格式"
})

add_keys('lib/l10n/intl_en.arb', {
  "menu_vision_error_unexpected_format": "Unexpected component format"
})
