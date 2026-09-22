// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh_TW locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'zh_TW';

  static String m0(error) => "連線助理時發生錯誤：${error}";

  static String m1(error) => "載入建議時發生錯誤：${error}";

  static String m2(winner) =>
      "🎲 命運轉盤為您抽出了最棒的選擇：\n👉 **${winner}** 👈\n祝您今晚用餐愉快，吃得開心滿足！";

  static String m3(error) => "菜單辨識失敗：${error}";

  static String m4(error) => "重試分析失敗：${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "a2ui_action_chip_group_title": MessageLookupByLibrary.simpleMessage(
      "快捷操作選項",
    ),
    "a2ui_comparison_item_name": MessageLookupByLibrary.simpleMessage("精選餐廳"),
    "a2ui_comparison_matrix_title": MessageLookupByLibrary.simpleMessage(
      "推薦餐廳對比",
    ),
    "a2ui_dish_catalog_empty": MessageLookupByLibrary.simpleMessage("菜單資料為空"),
    "a2ui_error_unknown_component": MessageLookupByLibrary.simpleMessage(
      "無法識別的 GenUI 元件結構",
    ),
    "account_section_title": MessageLookupByLibrary.simpleMessage("帳戶"),
    "ai_foodie_assistant_tooltip": MessageLookupByLibrary.simpleMessage(
      "AI 覓食助理",
    ),
    "ai_foodie_close_tooltip": MessageLookupByLibrary.simpleMessage("關閉"),
    "ai_foodie_error_connect_assistant": m0,
    "ai_foodie_error_load_suggestions": m1,
    "ai_foodie_input_hint": MessageLookupByLibrary.simpleMessage(
      "輸入情境，例如：4人想吃居酒屋聊聊天...",
    ),
    "ai_foodie_loading_hint": MessageLookupByLibrary.simpleMessage(
      "AI 正在為您精挑細選並比對美食中...",
    ),
    "ai_foodie_reset_tooltip": MessageLookupByLibrary.simpleMessage("重新開始"),
    "ai_foodie_roulette_awesome": MessageLookupByLibrary.simpleMessage("太棒了！"),
    "ai_foodie_roulette_default_title": MessageLookupByLibrary.simpleMessage(
      "今晚吃什麼？命運大轉盤",
    ),
    "ai_foodie_roulette_hint": MessageLookupByLibrary.simpleMessage(
      "點擊下方按鈕，讓命運幫您決定！",
    ),
    "ai_foodie_roulette_result_msg": m2,
    "ai_foodie_roulette_spin_again": MessageLookupByLibrary.simpleMessage(
      "再轉一次",
    ),
    "ai_foodie_roulette_spin_btn": MessageLookupByLibrary.simpleMessage(
      "🎲 轉動命運！",
    ),
    "ai_foodie_roulette_spinning": MessageLookupByLibrary.simpleMessage(
      "命運輪盤飛速旋轉中...",
    ),
    "ai_foodie_roulette_spinning_btn": MessageLookupByLibrary.simpleMessage(
      "轉動中...",
    ),
    "ai_foodie_roulette_winner_title": MessageLookupByLibrary.simpleMessage(
      "🎉 命運欽點！今晚就吃：",
    ),
    "ai_foodie_sheet_subtitle": MessageLookupByLibrary.simpleMessage(
      "生活化情境推薦 · 菜單對比 · 命運抽籤",
    ),
    "ai_foodie_sheet_title": MessageLookupByLibrary.simpleMessage("AI 智能覓食助理"),
    "allergen_risk_contains": MessageLookupByLibrary.simpleMessage("含"),
    "allergen_risk_may_contain": MessageLookupByLibrary.simpleMessage("可能含有"),
    "allergen_risk_none": MessageLookupByLibrary.simpleMessage("無"),
    "apply": MessageLookupByLibrary.simpleMessage("套用"),
    "auth_error_account_exists_different_credential":
        MessageLookupByLibrary.simpleMessage("此帳號已使用其他登入方式，請使用原始登入方式"),
    "auth_error_biometric_failed": MessageLookupByLibrary.simpleMessage(
      "生物識別認證失敗，請重新登入一次",
    ),
    "auth_error_email_already_in_use": MessageLookupByLibrary.simpleMessage(
      "此 Email 已被註冊，請使用其他 Email 註冊",
    ),
    "auth_error_email_not_verified": MessageLookupByLibrary.simpleMessage(
      "Email 尚未驗證，請使用驗證信驗證後再登入",
    ),
    "auth_error_invalid_email": MessageLookupByLibrary.simpleMessage(
      "無效的 Email，請重新輸入",
    ),
    "auth_error_sign_in_failed": MessageLookupByLibrary.simpleMessage(
      "登入失敗，請再試一次",
    ),
    "auth_error_user_not_found": MessageLookupByLibrary.simpleMessage(
      "帳號輸入錯誤或尚未註冊，請再試一次",
    ),
    "auth_error_weak_password": MessageLookupByLibrary.simpleMessage(
      "密碼強度不足，請使用其他字元組合",
    ),
    "auth_error_wrong_password": MessageLookupByLibrary.simpleMessage(
      "密碼錯誤，請再試一次",
    ),
    "biometric_prompt_reason": MessageLookupByLibrary.simpleMessage(
      "請使用生物識別認證進行登入",
    ),
    "business_hour": MessageLookupByLibrary.simpleMessage("營業時間"),
    "business_status_closed": MessageLookupByLibrary.simpleMessage("已打烊"),
    "business_status_open": MessageLookupByLibrary.simpleMessage("營業中"),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "comments": MessageLookupByLibrary.simpleMessage("評論"),
    "confirm": MessageLookupByLibrary.simpleMessage("確定"),
    "continue_as_guest": MessageLookupByLibrary.simpleMessage("訪客模式"),
    "delete_account_email_body": MessageLookupByLibrary.simpleMessage(
      "敬愛的團隊，我希望透過這封信來正式請求刪除我的帳號，以及與該帳號相關的所有個人資料和數據。帳號詳細資訊為:",
    ),
    "delete_account_email_subject": MessageLookupByLibrary.simpleMessage(
      "請求刪除我的帳號及相關數據",
    ),
    "delete_account_title": MessageLookupByLibrary.simpleMessage("刪除帳戶"),
    "dish_card_ingredients_prefix": MessageLookupByLibrary.simpleMessage(
      "主要食材：",
    ),
    "dish_card_spice_level_prefix": MessageLookupByLibrary.simpleMessage("辣度："),
    "dish_category_appetizer": MessageLookupByLibrary.simpleMessage("前菜"),
    "dish_category_beverage": MessageLookupByLibrary.simpleMessage("飲品"),
    "dish_category_dessert": MessageLookupByLibrary.simpleMessage("甜點"),
    "dish_category_main": MessageLookupByLibrary.simpleMessage("主食"),
    "dish_category_other": MessageLookupByLibrary.simpleMessage("其他"),
    "dish_category_soup": MessageLookupByLibrary.simpleMessage("湯品"),
    "email_invalid_hint_msg": MessageLookupByLibrary.simpleMessage(
      "請輸入正確Email",
    ),
    "email_invalid_hint_title": MessageLookupByLibrary.simpleMessage("Email帳號"),
    "email_signup_success_hint_msg": MessageLookupByLibrary.simpleMessage(
      "帳號建立成功, 請使用Email接收驗證連結並完成驗證",
    ),
    "email_signup_success_hint_title": MessageLookupByLibrary.simpleMessage(
      "Email帳號建立成功",
    ),
    "empty_data_retry": MessageLookupByLibrary.simpleMessage("重新嘗試"),
    "empty_data_subtitle": MessageLookupByLibrary.simpleMessage("試著調整關鍵字或過濾條件"),
    "empty_data_title": MessageLookupByLibrary.simpleMessage("目前無任何資料"),
    "error": MessageLookupByLibrary.simpleMessage("錯誤"),
    "error_and_retry": MessageLookupByLibrary.simpleMessage("發生錯誤請再試一次"),
    "favorite_store_add": MessageLookupByLibrary.simpleMessage("新增最愛店家"),
    "favorite_store_remove": MessageLookupByLibrary.simpleMessage("解除最愛店家"),
    "favorite_stores": MessageLookupByLibrary.simpleMessage("最愛店家"),
    "filter_business_hour": MessageLookupByLibrary.simpleMessage("營業時間"),
    "filter_price": MessageLookupByLibrary.simpleMessage("消費程度"),
    "filter_price_level1": MessageLookupByLibrary.simpleMessage("\$"),
    "filter_price_level2": MessageLookupByLibrary.simpleMessage("\$\$"),
    "filter_price_level3": MessageLookupByLibrary.simpleMessage("\$\$\$"),
    "filter_price_level4": MessageLookupByLibrary.simpleMessage("\$\$\$\$"),
    "filter_rules": MessageLookupByLibrary.simpleMessage("過濾條件"),
    "filter_sorting_rating": MessageLookupByLibrary.simpleMessage("評分"),
    "filter_sorting_review_count": MessageLookupByLibrary.simpleMessage("最多評論"),
    "filter_sorting_rule": MessageLookupByLibrary.simpleMessage("排序依據"),
    "filter_sorting_rule_best_match": MessageLookupByLibrary.simpleMessage(
      "最佳配對",
    ),
    "filter_sorting_rule_distance": MessageLookupByLibrary.simpleMessage("距離"),
    "information_section_title": MessageLookupByLibrary.simpleMessage("資訊"),
    "keyword_search": MessageLookupByLibrary.simpleMessage("關鍵字過濾"),
    "keyword_search_hint": MessageLookupByLibrary.simpleMessage("店名/分類/地區/路"),
    "list_mode": MessageLookupByLibrary.simpleMessage("列表模式"),
    "loading": MessageLookupByLibrary.simpleMessage("載入中..."),
    "logout_section_title": MessageLookupByLibrary.simpleMessage("登出"),
    "main_page_title": MessageLookupByLibrary.simpleMessage("尋找餐廳"),
    "map_mode": MessageLookupByLibrary.simpleMessage("地圖模式"),
    "map_my_loc_title": MessageLookupByLibrary.simpleMessage("我的位置"),
    "menu_vision_btn_camera": MessageLookupByLibrary.simpleMessage("拍照辨識菜單"),
    "menu_vision_btn_gallery": MessageLookupByLibrary.simpleMessage("從相簿選擇照片"),
    "menu_vision_btn_gallery_short": MessageLookupByLibrary.simpleMessage("相簿"),
    "menu_vision_btn_reselect_gallery": MessageLookupByLibrary.simpleMessage(
      "相簿重選",
    ),
    "menu_vision_btn_retake": MessageLookupByLibrary.simpleMessage("重新拍攝"),
    "menu_vision_btn_retry_photo": MessageLookupByLibrary.simpleMessage(
      "重試此照片",
    ),
    "menu_vision_btn_take_photo_short": MessageLookupByLibrary.simpleMessage(
      "拍照",
    ),
    "menu_vision_cancelled_subtitle": MessageLookupByLibrary.simpleMessage(
      "準備好時，可隨時點擊下方按鈕開始",
    ),
    "menu_vision_cancelled_title": MessageLookupByLibrary.simpleMessage(
      "已取消選取照片",
    ),
    "menu_vision_empty_dishes": MessageLookupByLibrary.simpleMessage(
      "未能成功辨識出菜色項目，請確認照片清晰後重試",
    ),
    "menu_vision_error_analyze_failed": m3,
    "menu_vision_error_retry_failed": m4,
    "menu_vision_error_unexpected_format": MessageLookupByLibrary.simpleMessage(
      "未預期的組件格式",
    ),
    "menu_vision_failure_title": MessageLookupByLibrary.simpleMessage("辨識未能完成"),
    "menu_vision_loading_subtitle": MessageLookupByLibrary.simpleMessage(
      "翻譯菜名、標註過敏原與食材拆解中，約需數秒",
    ),
    "menu_vision_loading_title": MessageLookupByLibrary.simpleMessage(
      "Gemini 正在分析菜單...",
    ),
    "menu_vision_prompt_subtitle": MessageLookupByLibrary.simpleMessage(
      "支援跨國菜單翻譯、食材拆解、過敏原警示與辣度分析",
    ),
    "menu_vision_prompt_title": MessageLookupByLibrary.simpleMessage(
      "拍下菜單，AI 立即辨識",
    ),
    "menu_vision_tab_all": MessageLookupByLibrary.simpleMessage("全部"),
    "menu_vision_title": MessageLookupByLibrary.simpleMessage("AI 菜單視覺翻譯"),
    "menu_vision_tooltip_camera": MessageLookupByLibrary.simpleMessage("拍照辨識"),
    "menu_vision_tooltip_close": MessageLookupByLibrary.simpleMessage("關閉"),
    "menu_vision_tooltip_gallery": MessageLookupByLibrary.simpleMessage(
      "從相簿選取",
    ),
    "navigation_choice": MessageLookupByLibrary.simpleMessage("請選擇導覽方式"),
    "passwd_invalid_hint_msg": MessageLookupByLibrary.simpleMessage("請輸入密碼"),
    "passwd_invalid_hint_title": MessageLookupByLibrary.simpleMessage("密碼"),
    "photo_viewer_title": MessageLookupByLibrary.simpleMessage("預覽"),
    "restaurant_detail_menu_vision_tooltip":
        MessageLookupByLibrary.simpleMessage("AI 拍照辨識菜單"),
    "review_count_suffix": MessageLookupByLibrary.simpleMessage("則評論"),
    "route_navigation": MessageLookupByLibrary.simpleMessage("導航"),
    "settings_title": MessageLookupByLibrary.simpleMessage("設定"),
    "signin_btn_title": MessageLookupByLibrary.simpleMessage("登入"),
    "signin_header_subtitle": MessageLookupByLibrary.simpleMessage("您的頂級餐飲嚮導"),
    "signin_or_signup_title": MessageLookupByLibrary.simpleMessage("登入 / 註冊"),
    "signin_page_title": MessageLookupByLibrary.simpleMessage("登入/註冊"),
    "signin_success_msg": MessageLookupByLibrary.simpleMessage("登入成功"),
    "signinup_with_apple": MessageLookupByLibrary.simpleMessage("使用Apple繼續"),
    "signinup_with_apple_hint_msg": MessageLookupByLibrary.simpleMessage(
      "Apple登入成功",
    ),
    "signinup_with_fb": MessageLookupByLibrary.simpleMessage("使用Facebook繼續"),
    "signinup_with_fb_hint_msg": MessageLookupByLibrary.simpleMessage(
      "Facebook登入成功",
    ),
    "signinup_with_google": MessageLookupByLibrary.simpleMessage("使用Google繼續"),
    "signinup_with_google_hint_msg": MessageLookupByLibrary.simpleMessage(
      "Google登入成功",
    ),
    "signup_title": MessageLookupByLibrary.simpleMessage("註冊新帳號"),
    "street_view": MessageLookupByLibrary.simpleMessage("街景視圖"),
    "version_tile_title": MessageLookupByLibrary.simpleMessage("版本"),
    "weekday_friday": MessageLookupByLibrary.simpleMessage("星期五"),
    "weekday_monday": MessageLookupByLibrary.simpleMessage("星期一"),
    "weekday_saturday": MessageLookupByLibrary.simpleMessage("星期六"),
    "weekday_sunday": MessageLookupByLibrary.simpleMessage("星期日"),
    "weekday_thursday": MessageLookupByLibrary.simpleMessage("星期四"),
    "weekday_tuesday": MessageLookupByLibrary.simpleMessage("星期二"),
    "weekday_wednesday": MessageLookupByLibrary.simpleMessage("星期三"),
  };
}
