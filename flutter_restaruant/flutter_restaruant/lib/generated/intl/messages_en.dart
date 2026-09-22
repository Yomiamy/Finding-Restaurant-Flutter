// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(error) => "Error connecting to assistant: ${error}";

  static String m1(error) => "Error loading suggestions: ${error}";

  static String m2(winner) =>
      "🎲 Decision roulette selected the top choice for you:\n👉 **${winner}** 👈\nWishing you a delightful dining experience!";

  static String m3(error) => "Menu recognition failed: ${error}";

  static String m4(error) => "Retry analysis failed: ${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "a2ui_action_chip_group_title": MessageLookupByLibrary.simpleMessage(
      "Quick Actions",
    ),
    "a2ui_comparison_item_name": MessageLookupByLibrary.simpleMessage(
      "Selected Restaurant",
    ),
    "a2ui_comparison_matrix_title": MessageLookupByLibrary.simpleMessage(
      "Recommended Restaurant Comparison",
    ),
    "a2ui_dish_catalog_empty": MessageLookupByLibrary.simpleMessage(
      "Menu data is empty",
    ),
    "a2ui_error_unknown_component": MessageLookupByLibrary.simpleMessage(
      "Unrecognized GenUI component structure",
    ),
    "account_section_title": MessageLookupByLibrary.simpleMessage("Account"),
    "ai_foodie_assistant_tooltip": MessageLookupByLibrary.simpleMessage(
      "AI Foodie Assistant",
    ),
    "ai_foodie_close_tooltip": MessageLookupByLibrary.simpleMessage("Close"),
    "ai_foodie_error_connect_assistant": m0,
    "ai_foodie_error_load_suggestions": m1,
    "ai_foodie_input_hint": MessageLookupByLibrary.simpleMessage(
      "Enter scenario, e.g. 4 people wanting izakaya to chat...",
    ),
    "ai_foodie_loading_hint": MessageLookupByLibrary.simpleMessage(
      "AI is curating and comparing culinary gems for you...",
    ),
    "ai_foodie_reset_tooltip": MessageLookupByLibrary.simpleMessage("Reset"),
    "ai_foodie_roulette_awesome": MessageLookupByLibrary.simpleMessage(
      "Awesome!",
    ),
    "ai_foodie_roulette_default_title": MessageLookupByLibrary.simpleMessage(
      "What to eat tonight? Decision Roulette",
    ),
    "ai_foodie_roulette_hint": MessageLookupByLibrary.simpleMessage(
      "Tap the button below and let destiny choose!",
    ),
    "ai_foodie_roulette_result_msg": m2,
    "ai_foodie_roulette_spin_again": MessageLookupByLibrary.simpleMessage(
      "Spin Again",
    ),
    "ai_foodie_roulette_spin_btn": MessageLookupByLibrary.simpleMessage(
      "🎲 Spin the Wheel!",
    ),
    "ai_foodie_roulette_spinning": MessageLookupByLibrary.simpleMessage(
      "The roulette wheel is spinning rapidly...",
    ),
    "ai_foodie_roulette_spinning_btn": MessageLookupByLibrary.simpleMessage(
      "Spinning...",
    ),
    "ai_foodie_roulette_winner_title": MessageLookupByLibrary.simpleMessage(
      "🎉 Destiny decided! Tonight we eat:",
    ),
    "ai_foodie_sheet_subtitle": MessageLookupByLibrary.simpleMessage(
      "Contextual Recommendations · Menu Comparison · Decision Roulette",
    ),
    "ai_foodie_sheet_title": MessageLookupByLibrary.simpleMessage(
      "AI Foodie Assistant",
    ),
    "allergen_risk_contains": MessageLookupByLibrary.simpleMessage("Contains"),
    "allergen_risk_may_contain": MessageLookupByLibrary.simpleMessage(
      "May Contain",
    ),
    "allergen_risk_none": MessageLookupByLibrary.simpleMessage("Free"),
    "apply": MessageLookupByLibrary.simpleMessage("Apply"),
    "auth_error_account_exists_different_credential":
        MessageLookupByLibrary.simpleMessage(
          "An account already exists with a different credential. Please sign in using the original provider",
        ),
    "auth_error_biometric_failed": MessageLookupByLibrary.simpleMessage(
      "Biometric authentication failed, please try again",
    ),
    "auth_error_email_already_in_use": MessageLookupByLibrary.simpleMessage(
      "Email already registered, please use another email to register",
    ),
    "auth_error_email_not_verified": MessageLookupByLibrary.simpleMessage(
      "Email not verified yet. Please check your verification email before signing in",
    ),
    "auth_error_invalid_email": MessageLookupByLibrary.simpleMessage(
      "Invalid email, please enter again",
    ),
    "auth_error_sign_in_failed": MessageLookupByLibrary.simpleMessage(
      "Sign in failed, please try again",
    ),
    "auth_error_user_not_found": MessageLookupByLibrary.simpleMessage(
      "Account not found or not registered, please try again",
    ),
    "auth_error_weak_password": MessageLookupByLibrary.simpleMessage(
      "Password security is low, please use another character combination",
    ),
    "auth_error_wrong_password": MessageLookupByLibrary.simpleMessage(
      "Incorrect password, please try again",
    ),
    "biometric_prompt_reason": MessageLookupByLibrary.simpleMessage(
      "Please authenticate to sign in",
    ),
    "business_hour": MessageLookupByLibrary.simpleMessage("Business Hour"),
    "business_status_closed": MessageLookupByLibrary.simpleMessage("CLOSED"),
    "business_status_open": MessageLookupByLibrary.simpleMessage("OPEN"),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "comments": MessageLookupByLibrary.simpleMessage("Reviews"),
    "confirm": MessageLookupByLibrary.simpleMessage("Ok"),
    "continue_as_guest": MessageLookupByLibrary.simpleMessage(
      "Continue As Guest",
    ),
    "delete_account_email_body": MessageLookupByLibrary.simpleMessage(
      "Dear Team, I am writing to formally request the deletion of my account and all associated personal data. Please find the details of my account:",
    ),
    "delete_account_email_subject": MessageLookupByLibrary.simpleMessage(
      "Request for Account Deletion and Data Removal",
    ),
    "delete_account_title": MessageLookupByLibrary.simpleMessage(
      "Delete Account",
    ),
    "dish_card_ingredients_prefix": MessageLookupByLibrary.simpleMessage(
      "Main Ingredients: ",
    ),
    "dish_card_spice_level_prefix": MessageLookupByLibrary.simpleMessage(
      "Spiciness: ",
    ),
    "dish_category_appetizer": MessageLookupByLibrary.simpleMessage(
      "Appetizer",
    ),
    "dish_category_beverage": MessageLookupByLibrary.simpleMessage("Beverage"),
    "dish_category_dessert": MessageLookupByLibrary.simpleMessage("Dessert"),
    "dish_category_main": MessageLookupByLibrary.simpleMessage("Main"),
    "dish_category_other": MessageLookupByLibrary.simpleMessage("Other"),
    "dish_category_soup": MessageLookupByLibrary.simpleMessage("Soup"),
    "email_invalid_hint_msg": MessageLookupByLibrary.simpleMessage(
      "Please input email",
    ),
    "email_invalid_hint_title": MessageLookupByLibrary.simpleMessage(
      "Email Account",
    ),
    "email_signup_success_hint_msg": MessageLookupByLibrary.simpleMessage(
      "Account created successfully, please receive the confirmation link in the email and verification",
    ),
    "email_signup_success_hint_title": MessageLookupByLibrary.simpleMessage(
      "Email signup successfully",
    ),
    "empty_data_retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "empty_data_subtitle": MessageLookupByLibrary.simpleMessage(
      "Try adjusting your keywords or filters",
    ),
    "empty_data_title": MessageLookupByLibrary.simpleMessage(
      "No Data Available",
    ),
    "error": MessageLookupByLibrary.simpleMessage("Error"),
    "error_and_retry": MessageLookupByLibrary.simpleMessage(
      "Please retry again.",
    ),
    "favorite_store_add": MessageLookupByLibrary.simpleMessage(
      "Add in favorite list",
    ),
    "favorite_store_remove": MessageLookupByLibrary.simpleMessage(
      "Remove from favorite list",
    ),
    "favorite_stores": MessageLookupByLibrary.simpleMessage("favorite stores"),
    "filter_business_hour": MessageLookupByLibrary.simpleMessage(
      "Business Hour",
    ),
    "filter_price": MessageLookupByLibrary.simpleMessage("Price Rule"),
    "filter_price_level1": MessageLookupByLibrary.simpleMessage("\$"),
    "filter_price_level2": MessageLookupByLibrary.simpleMessage("\$\$"),
    "filter_price_level3": MessageLookupByLibrary.simpleMessage("\$\$\$"),
    "filter_price_level4": MessageLookupByLibrary.simpleMessage("\$\$\$\$"),
    "filter_rules": MessageLookupByLibrary.simpleMessage("Filter Rules"),
    "filter_sorting_rating": MessageLookupByLibrary.simpleMessage("Rating"),
    "filter_sorting_review_count": MessageLookupByLibrary.simpleMessage(
      "Review Count",
    ),
    "filter_sorting_rule": MessageLookupByLibrary.simpleMessage("Sorting Rule"),
    "filter_sorting_rule_best_match": MessageLookupByLibrary.simpleMessage(
      "Best Match",
    ),
    "filter_sorting_rule_distance": MessageLookupByLibrary.simpleMessage(
      "Distance",
    ),
    "information_section_title": MessageLookupByLibrary.simpleMessage(
      "Information",
    ),
    "keyword_search": MessageLookupByLibrary.simpleMessage("Keyword Search"),
    "keyword_search_hint": MessageLookupByLibrary.simpleMessage(
      "Store/Category/Street...",
    ),
    "list_mode": MessageLookupByLibrary.simpleMessage("List Mode"),
    "loading": MessageLookupByLibrary.simpleMessage("Loading..."),
    "logout_section_title": MessageLookupByLibrary.simpleMessage("Logout"),
    "main_page_title": MessageLookupByLibrary.simpleMessage("FindRestaurant"),
    "map_mode": MessageLookupByLibrary.simpleMessage("Map Mode"),
    "map_my_loc_title": MessageLookupByLibrary.simpleMessage("I am here"),
    "menu_vision_btn_camera": MessageLookupByLibrary.simpleMessage(
      "Take Photo to Recognize",
    ),
    "menu_vision_btn_gallery": MessageLookupByLibrary.simpleMessage(
      "Choose from Gallery",
    ),
    "menu_vision_btn_gallery_short": MessageLookupByLibrary.simpleMessage(
      "Gallery",
    ),
    "menu_vision_btn_reselect_gallery": MessageLookupByLibrary.simpleMessage(
      "Choose from gallery",
    ),
    "menu_vision_btn_retake": MessageLookupByLibrary.simpleMessage("Retake"),
    "menu_vision_btn_retry_photo": MessageLookupByLibrary.simpleMessage(
      "Retry this photo",
    ),
    "menu_vision_btn_take_photo_short": MessageLookupByLibrary.simpleMessage(
      "Camera",
    ),
    "menu_vision_cancelled_subtitle": MessageLookupByLibrary.simpleMessage(
      "Whenever you are ready, click below to start",
    ),
    "menu_vision_cancelled_title": MessageLookupByLibrary.simpleMessage(
      "Photo selection cancelled",
    ),
    "menu_vision_empty_dishes": MessageLookupByLibrary.simpleMessage(
      "No dish items recognized. Please ensure photo is clear and try again",
    ),
    "menu_vision_error_analyze_failed": m3,
    "menu_vision_error_retry_failed": m4,
    "menu_vision_error_unexpected_format": MessageLookupByLibrary.simpleMessage(
      "Unexpected component format",
    ),
    "menu_vision_failure_title": MessageLookupByLibrary.simpleMessage(
      "Recognition Failed",
    ),
    "menu_vision_loading_subtitle": MessageLookupByLibrary.simpleMessage(
      "Translating dishes, marking allergens, and breaking down ingredients. Takes a few seconds",
    ),
    "menu_vision_loading_title": MessageLookupByLibrary.simpleMessage(
      "Gemini is analyzing the menu...",
    ),
    "menu_vision_prompt_subtitle": MessageLookupByLibrary.simpleMessage(
      "Supports cross-border menu translation, ingredient breakdown, allergen alerts, and spiciness analysis",
    ),
    "menu_vision_prompt_title": MessageLookupByLibrary.simpleMessage(
      "Snap Menu, AI Recognizes Instantly",
    ),
    "menu_vision_tab_all": MessageLookupByLibrary.simpleMessage("All"),
    "menu_vision_title": MessageLookupByLibrary.simpleMessage(
      "AI Menu Visual Translation",
    ),
    "menu_vision_tooltip_camera": MessageLookupByLibrary.simpleMessage(
      "Take photo",
    ),
    "menu_vision_tooltip_close": MessageLookupByLibrary.simpleMessage("Close"),
    "menu_vision_tooltip_gallery": MessageLookupByLibrary.simpleMessage(
      "Choose from gallery",
    ),
    "navigation_choice": MessageLookupByLibrary.simpleMessage(
      "Navigation Choice",
    ),
    "passwd_invalid_hint_msg": MessageLookupByLibrary.simpleMessage(
      "Please input password",
    ),
    "passwd_invalid_hint_title": MessageLookupByLibrary.simpleMessage(
      "Password",
    ),
    "photo_viewer_title": MessageLookupByLibrary.simpleMessage("Photo Viewer"),
    "restaurant_detail_menu_vision_tooltip":
        MessageLookupByLibrary.simpleMessage("AI Menu Vision Recognition"),
    "review_count_suffix": MessageLookupByLibrary.simpleMessage(" reviews"),
    "route_navigation": MessageLookupByLibrary.simpleMessage(
      "Route Navigation",
    ),
    "settings_title": MessageLookupByLibrary.simpleMessage("Settings"),
    "signin_btn_title": MessageLookupByLibrary.simpleMessage("SignIn"),
    "signin_header_subtitle": MessageLookupByLibrary.simpleMessage(
      "Your premium dining concierge.",
    ),
    "signin_or_signup_title": MessageLookupByLibrary.simpleMessage(
      "SignIn / SignUp",
    ),
    "signin_page_title": MessageLookupByLibrary.simpleMessage("SignIn/SignUp"),
    "signin_success_msg": MessageLookupByLibrary.simpleMessage(
      "SignIn successfully",
    ),
    "signinup_with_apple": MessageLookupByLibrary.simpleMessage(
      "Continue with Apple",
    ),
    "signinup_with_apple_hint_msg": MessageLookupByLibrary.simpleMessage(
      "Apple SignIn",
    ),
    "signinup_with_fb": MessageLookupByLibrary.simpleMessage(
      "Continue with Facebook",
    ),
    "signinup_with_fb_hint_msg": MessageLookupByLibrary.simpleMessage(
      "Facebook SignIn",
    ),
    "signinup_with_google": MessageLookupByLibrary.simpleMessage(
      "Continue with Google",
    ),
    "signinup_with_google_hint_msg": MessageLookupByLibrary.simpleMessage(
      "Google SignIn",
    ),
    "signup_title": MessageLookupByLibrary.simpleMessage("SignUp"),
    "street_view": MessageLookupByLibrary.simpleMessage("Street View"),
    "version_tile_title": MessageLookupByLibrary.simpleMessage("Version"),
    "weekday_friday": MessageLookupByLibrary.simpleMessage("Friday"),
    "weekday_monday": MessageLookupByLibrary.simpleMessage("Monday"),
    "weekday_saturday": MessageLookupByLibrary.simpleMessage("Saturday"),
    "weekday_sunday": MessageLookupByLibrary.simpleMessage("Sunday"),
    "weekday_thursday": MessageLookupByLibrary.simpleMessage("Thursday"),
    "weekday_tuesday": MessageLookupByLibrary.simpleMessage("Tuesday"),
    "weekday_wednesday": MessageLookupByLibrary.simpleMessage("Wednesday"),
  };
}
