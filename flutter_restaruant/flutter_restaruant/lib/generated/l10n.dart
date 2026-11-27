// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Error`
  String get error {
    return Intl.message('Error', name: 'error', desc: '', args: []);
  }

  /// `Please retry again.`
  String get error_and_retry {
    return Intl.message(
      'Please retry again.',
      name: 'error_and_retry',
      desc: '',
      args: [],
    );
  }

  /// `Ok`
  String get confirm {
    return Intl.message('Ok', name: 'confirm', desc: '', args: []);
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Apply`
  String get apply {
    return Intl.message('Apply', name: 'apply', desc: '', args: []);
  }

  /// `Filter Rules`
  String get filter_rules {
    return Intl.message(
      'Filter Rules',
      name: 'filter_rules',
      desc: '',
      args: [],
    );
  }

  /// `Price Rule`
  String get filter_price {
    return Intl.message('Price Rule', name: 'filter_price', desc: '', args: []);
  }

  /// `$`
  String get filter_price_level1 {
    return Intl.message('\$', name: 'filter_price_level1', desc: '', args: []);
  }

  /// `$$`
  String get filter_price_level2 {
    return Intl.message(
      '\$\$',
      name: 'filter_price_level2',
      desc: '',
      args: [],
    );
  }

  /// `$$$`
  String get filter_price_level3 {
    return Intl.message(
      '\$\$\$',
      name: 'filter_price_level3',
      desc: '',
      args: [],
    );
  }

  /// `$$$$`
  String get filter_price_level4 {
    return Intl.message(
      '\$\$\$\$',
      name: 'filter_price_level4',
      desc: '',
      args: [],
    );
  }

  /// `Business Hour`
  String get filter_business_hour {
    return Intl.message(
      'Business Hour',
      name: 'filter_business_hour',
      desc: '',
      args: [],
    );
  }

  /// `Sorting Rule`
  String get filter_sorting_rule {
    return Intl.message(
      'Sorting Rule',
      name: 'filter_sorting_rule',
      desc: '',
      args: [],
    );
  }

  /// `Best Match`
  String get filter_sorting_rule_best_match {
    return Intl.message(
      'Best Match',
      name: 'filter_sorting_rule_best_match',
      desc: '',
      args: [],
    );
  }

  /// `Distance`
  String get filter_sorting_rule_distance {
    return Intl.message(
      'Distance',
      name: 'filter_sorting_rule_distance',
      desc: '',
      args: [],
    );
  }

  /// `Rating`
  String get filter_sorting_rating {
    return Intl.message(
      'Rating',
      name: 'filter_sorting_rating',
      desc: '',
      args: [],
    );
  }

  /// `Review Count`
  String get filter_sorting_review_count {
    return Intl.message(
      'Review Count',
      name: 'filter_sorting_review_count',
      desc: '',
      args: [],
    );
  }

  /// `Cuisine Category`
  String get filter_cuisine_category {
    return Intl.message(
      'Cuisine Category',
      name: 'filter_cuisine_category',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get filter_cuisine_all {
    return Intl.message('All', name: 'filter_cuisine_all', desc: '', args: []);
  }

  /// `Open Now`
  String get filter_open_now {
    return Intl.message(
      'Open Now',
      name: 'filter_open_now',
      desc: '',
      args: [],
    );
  }

  /// `Show only restaurants open right now (ignores specific time)`
  String get filter_open_now_subtitle {
    return Intl.message(
      'Show only restaurants open right now (ignores specific time)',
      name: 'filter_open_now_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Search Radius`
  String get filter_search_radius {
    return Intl.message(
      'Search Radius',
      name: 'filter_search_radius',
      desc: '',
      args: [],
    );
  }

  /// `Unlimited`
  String get filter_radius_unlimited {
    return Intl.message(
      'Unlimited',
      name: 'filter_radius_unlimited',
      desc: '',
      args: [],
    );
  }

  /// `{meters} m`
  String filter_radius_meters(Object meters) {
    return Intl.message(
      '$meters m',
      name: 'filter_radius_meters',
      desc: '',
      args: [meters],
    );
  }

  /// `{km} km`
  String filter_radius_kilometers(Object km) {
    return Intl.message(
      '$km km',
      name: 'filter_radius_kilometers',
      desc: '',
      args: [km],
    );
  }

  /// `FindRestaurant`
  String get main_page_title {
    return Intl.message(
      'FindRestaurant',
      name: 'main_page_title',
      desc: '',
      args: [],
    );
  }

  /// `Keyword Search`
  String get keyword_search {
    return Intl.message(
      'Keyword Search',
      name: 'keyword_search',
      desc: '',
      args: [],
    );
  }

  /// `Store/Category/Street...`
  String get keyword_search_hint {
    return Intl.message(
      'Store/Category/Street...',
      name: 'keyword_search_hint',
      desc: '',
      args: [],
    );
  }

  /// `I am here`
  String get map_my_loc_title {
    return Intl.message(
      'I am here',
      name: 'map_my_loc_title',
      desc: '',
      args: [],
    );
  }

  /// `Map Mode`
  String get map_mode {
    return Intl.message('Map Mode', name: 'map_mode', desc: '', args: []);
  }

  /// `List Mode`
  String get list_mode {
    return Intl.message('List Mode', name: 'list_mode', desc: '', args: []);
  }

  /// `Photo Viewer`
  String get photo_viewer_title {
    return Intl.message(
      'Photo Viewer',
      name: 'photo_viewer_title',
      desc: '',
      args: [],
    );
  }

  /// ` reviews`
  String get review_count_suffix {
    return Intl.message(
      ' reviews',
      name: 'review_count_suffix',
      desc: '',
      args: [],
    );
  }

  /// `Navigation Choice`
  String get navigation_choice {
    return Intl.message(
      'Navigation Choice',
      name: 'navigation_choice',
      desc: '',
      args: [],
    );
  }

  /// `Route Navigation`
  String get route_navigation {
    return Intl.message(
      'Route Navigation',
      name: 'route_navigation',
      desc: '',
      args: [],
    );
  }

  /// `Street View`
  String get street_view {
    return Intl.message('Street View', name: 'street_view', desc: '', args: []);
  }

  /// `favorite stores`
  String get favorite_stores {
    return Intl.message(
      'favorite stores',
      name: 'favorite_stores',
      desc: '',
      args: [],
    );
  }

  /// `Add in favorite list`
  String get favorite_store_add {
    return Intl.message(
      'Add in favorite list',
      name: 'favorite_store_add',
      desc: '',
      args: [],
    );
  }

  /// `Remove from favorite list`
  String get favorite_store_remove {
    return Intl.message(
      'Remove from favorite list',
      name: 'favorite_store_remove',
      desc: '',
      args: [],
    );
  }

  /// `Business Hour`
  String get business_hour {
    return Intl.message(
      'Business Hour',
      name: 'business_hour',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings_title {
    return Intl.message('Settings', name: 'settings_title', desc: '', args: []);
  }

  /// `Information`
  String get information_section_title {
    return Intl.message(
      'Information',
      name: 'information_section_title',
      desc: '',
      args: [],
    );
  }

  /// `Version`
  String get version_tile_title {
    return Intl.message(
      'Version',
      name: 'version_tile_title',
      desc: '',
      args: [],
    );
  }

  /// `Account`
  String get account_section_title {
    return Intl.message(
      'Account',
      name: 'account_section_title',
      desc: '',
      args: [],
    );
  }

  /// `Logout`
  String get logout_section_title {
    return Intl.message(
      'Logout',
      name: 'logout_section_title',
      desc: '',
      args: [],
    );
  }

  /// `Delete Account`
  String get delete_account_title {
    return Intl.message(
      'Delete Account',
      name: 'delete_account_title',
      desc: '',
      args: [],
    );
  }

  /// `Request for Account Deletion and Data Removal`
  String get delete_account_email_subject {
    return Intl.message(
      'Request for Account Deletion and Data Removal',
      name: 'delete_account_email_subject',
      desc: '',
      args: [],
    );
  }

  /// `Dear Team, I am writing to formally request the deletion of my account and all associated personal data. Please find the details of my account:`
  String get delete_account_email_body {
    return Intl.message(
      'Dear Team, I am writing to formally request the deletion of my account and all associated personal data. Please find the details of my account:',
      name: 'delete_account_email_body',
      desc: '',
      args: [],
    );
  }

  /// `SignIn/SignUp`
  String get signin_page_title {
    return Intl.message(
      'SignIn/SignUp',
      name: 'signin_page_title',
      desc: '',
      args: [],
    );
  }

  /// `SignIn successfully`
  String get signin_success_msg {
    return Intl.message(
      'SignIn successfully',
      name: 'signin_success_msg',
      desc: '',
      args: [],
    );
  }

  /// `Email signup successfully`
  String get email_signup_success_hint_title {
    return Intl.message(
      'Email signup successfully',
      name: 'email_signup_success_hint_title',
      desc: '',
      args: [],
    );
  }

  /// `Account created successfully, please receive the confirmation link in the email and verification`
  String get email_signup_success_hint_msg {
    return Intl.message(
      'Account created successfully, please receive the confirmation link in the email and verification',
      name: 'email_signup_success_hint_msg',
      desc: '',
      args: [],
    );
  }

  /// `Please input email`
  String get email_invalid_hint_msg {
    return Intl.message(
      'Please input email',
      name: 'email_invalid_hint_msg',
      desc: '',
      args: [],
    );
  }

  /// `Email Account`
  String get email_invalid_hint_title {
    return Intl.message(
      'Email Account',
      name: 'email_invalid_hint_title',
      desc: '',
      args: [],
    );
  }

  /// `Please input password`
  String get passwd_invalid_hint_msg {
    return Intl.message(
      'Please input password',
      name: 'passwd_invalid_hint_msg',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get passwd_invalid_hint_title {
    return Intl.message(
      'Password',
      name: 'passwd_invalid_hint_title',
      desc: '',
      args: [],
    );
  }

  /// `SignIn`
  String get signin_btn_title {
    return Intl.message('SignIn', name: 'signin_btn_title', desc: '', args: []);
  }

  /// `SignUp`
  String get signup_title {
    return Intl.message('SignUp', name: 'signup_title', desc: '', args: []);
  }

  /// `Continue with Google`
  String get signinup_with_google {
    return Intl.message(
      'Continue with Google',
      name: 'signinup_with_google',
      desc: '',
      args: [],
    );
  }

  /// `Google SignIn`
  String get signinup_with_google_hint_msg {
    return Intl.message(
      'Google SignIn',
      name: 'signinup_with_google_hint_msg',
      desc: '',
      args: [],
    );
  }

  /// `Continue with Facebook`
  String get signinup_with_fb {
    return Intl.message(
      'Continue with Facebook',
      name: 'signinup_with_fb',
      desc: '',
      args: [],
    );
  }

  /// `Facebook SignIn`
  String get signinup_with_fb_hint_msg {
    return Intl.message(
      'Facebook SignIn',
      name: 'signinup_with_fb_hint_msg',
      desc: '',
      args: [],
    );
  }

  /// `Continue with Apple`
  String get signinup_with_apple {
    return Intl.message(
      'Continue with Apple',
      name: 'signinup_with_apple',
      desc: '',
      args: [],
    );
  }

  /// `Apple SignIn`
  String get signinup_with_apple_hint_msg {
    return Intl.message(
      'Apple SignIn',
      name: 'signinup_with_apple_hint_msg',
      desc: '',
      args: [],
    );
  }

  /// `Continue As Guest`
  String get continue_as_guest {
    return Intl.message(
      'Continue As Guest',
      name: 'continue_as_guest',
      desc: '',
      args: [],
    );
  }

  /// `SignIn / SignUp`
  String get signin_or_signup_title {
    return Intl.message(
      'SignIn / SignUp',
      name: 'signin_or_signup_title',
      desc: '',
      args: [],
    );
  }

  /// `No Data Available`
  String get empty_data_title {
    return Intl.message(
      'No Data Available',
      name: 'empty_data_title',
      desc: '',
      args: [],
    );
  }

  /// `Try adjusting your keywords or filters`
  String get empty_data_subtitle {
    return Intl.message(
      'Try adjusting your keywords or filters',
      name: 'empty_data_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get empty_data_retry {
    return Intl.message('Retry', name: 'empty_data_retry', desc: '', args: []);
  }

  /// `Reviews`
  String get comments {
    return Intl.message('Reviews', name: 'comments', desc: '', args: []);
  }

  /// `OPEN`
  String get business_status_open {
    return Intl.message(
      'OPEN',
      name: 'business_status_open',
      desc: '',
      args: [],
    );
  }

  /// `CLOSED`
  String get business_status_closed {
    return Intl.message(
      'CLOSED',
      name: 'business_status_closed',
      desc: '',
      args: [],
    );
  }

  /// `Your premium dining concierge.`
  String get signin_header_subtitle {
    return Intl.message(
      'Your premium dining concierge.',
      name: 'signin_header_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `AI Foodie Assistant`
  String get ai_foodie_assistant_tooltip {
    return Intl.message(
      'AI Foodie Assistant',
      name: 'ai_foodie_assistant_tooltip',
      desc: '',
      args: [],
    );
  }

  /// `AI Foodie Assistant`
  String get ai_foodie_sheet_title {
    return Intl.message(
      'AI Foodie Assistant',
      name: 'ai_foodie_sheet_title',
      desc: '',
      args: [],
    );
  }

  /// `Contextual Recommendations · Menu Comparison · Decision Roulette`
  String get ai_foodie_sheet_subtitle {
    return Intl.message(
      'Contextual Recommendations · Menu Comparison · Decision Roulette',
      name: 'ai_foodie_sheet_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Reset`
  String get ai_foodie_reset_tooltip {
    return Intl.message(
      'Reset',
      name: 'ai_foodie_reset_tooltip',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get ai_foodie_close_tooltip {
    return Intl.message(
      'Close',
      name: 'ai_foodie_close_tooltip',
      desc: '',
      args: [],
    );
  }

  /// `Enter scenario, e.g. 4 people wanting izakaya to chat...`
  String get ai_foodie_input_hint {
    return Intl.message(
      'Enter scenario, e.g. 4 people wanting izakaya to chat...',
      name: 'ai_foodie_input_hint',
      desc: '',
      args: [],
    );
  }

  /// `AI is curating and comparing culinary gems for you...`
  String get ai_foodie_loading_hint {
    return Intl.message(
      'AI is curating and comparing culinary gems for you...',
      name: 'ai_foodie_loading_hint',
      desc: '',
      args: [],
    );
  }

  /// `🎉 Destiny decided! Tonight we eat:`
  String get ai_foodie_roulette_winner_title {
    return Intl.message(
      '🎉 Destiny decided! Tonight we eat:',
      name: 'ai_foodie_roulette_winner_title',
      desc: '',
      args: [],
    );
  }

  /// `The roulette wheel is spinning rapidly...`
  String get ai_foodie_roulette_spinning {
    return Intl.message(
      'The roulette wheel is spinning rapidly...',
      name: 'ai_foodie_roulette_spinning',
      desc: '',
      args: [],
    );
  }

  /// `Tap the button below and let destiny choose!`
  String get ai_foodie_roulette_hint {
    return Intl.message(
      'Tap the button below and let destiny choose!',
      name: 'ai_foodie_roulette_hint',
      desc: '',
      args: [],
    );
  }

  /// `Spin Again`
  String get ai_foodie_roulette_spin_again {
    return Intl.message(
      'Spin Again',
      name: 'ai_foodie_roulette_spin_again',
      desc: '',
      args: [],
    );
  }

  /// `Awesome!`
  String get ai_foodie_roulette_awesome {
    return Intl.message(
      'Awesome!',
      name: 'ai_foodie_roulette_awesome',
      desc: '',
      args: [],
    );
  }

  /// `🎲 Spin the Wheel!`
  String get ai_foodie_roulette_spin_btn {
    return Intl.message(
      '🎲 Spin the Wheel!',
      name: 'ai_foodie_roulette_spin_btn',
      desc: '',
      args: [],
    );
  }

  /// `Spinning...`
  String get ai_foodie_roulette_spinning_btn {
    return Intl.message(
      'Spinning...',
      name: 'ai_foodie_roulette_spinning_btn',
      desc: '',
      args: [],
    );
  }

  /// `What to eat tonight? Decision Roulette`
  String get ai_foodie_roulette_default_title {
    return Intl.message(
      'What to eat tonight? Decision Roulette',
      name: 'ai_foodie_roulette_default_title',
      desc: '',
      args: [],
    );
  }

  /// `🎲 Decision roulette selected the top choice for you:\n👉 **{winner}** 👈\nWishing you a delightful dining experience!`
  String ai_foodie_roulette_result_msg(Object winner) {
    return Intl.message(
      '🎲 Decision roulette selected the top choice for you:\n👉 **$winner** 👈\nWishing you a delightful dining experience!',
      name: 'ai_foodie_roulette_result_msg',
      desc: '',
      args: [winner],
    );
  }

  /// `Error loading suggestions: {error}`
  String ai_foodie_error_load_suggestions(Object error) {
    return Intl.message(
      'Error loading suggestions: $error',
      name: 'ai_foodie_error_load_suggestions',
      desc: '',
      args: [error],
    );
  }

  /// `Error connecting to assistant: {error}`
  String ai_foodie_error_connect_assistant(Object error) {
    return Intl.message(
      'Error connecting to assistant: $error',
      name: 'ai_foodie_error_connect_assistant',
      desc: '',
      args: [error],
    );
  }

  /// `Unrecognized GenUI component structure`
  String get a2ui_error_unknown_component {
    return Intl.message(
      'Unrecognized GenUI component structure',
      name: 'a2ui_error_unknown_component',
      desc: '',
      args: [],
    );
  }

  /// `Menu data is empty`
  String get a2ui_dish_catalog_empty {
    return Intl.message(
      'Menu data is empty',
      name: 'a2ui_dish_catalog_empty',
      desc: '',
      args: [],
    );
  }

  /// `Recommended Restaurant Comparison`
  String get a2ui_comparison_matrix_title {
    return Intl.message(
      'Recommended Restaurant Comparison',
      name: 'a2ui_comparison_matrix_title',
      desc: '',
      args: [],
    );
  }

  /// `Selected Restaurant`
  String get a2ui_comparison_item_name {
    return Intl.message(
      'Selected Restaurant',
      name: 'a2ui_comparison_item_name',
      desc: '',
      args: [],
    );
  }

  /// `Quick Actions`
  String get a2ui_action_chip_group_title {
    return Intl.message(
      'Quick Actions',
      name: 'a2ui_action_chip_group_title',
      desc: '',
      args: [],
    );
  }

  /// `Unexpected component format`
  String get menu_vision_error_unexpected_format {
    return Intl.message(
      'Unexpected component format',
      name: 'menu_vision_error_unexpected_format',
      desc: '',
      args: [],
    );
  }

  /// `Menu recognition failed: {error}`
  String menu_vision_error_analyze_failed(Object error) {
    return Intl.message(
      'Menu recognition failed: $error',
      name: 'menu_vision_error_analyze_failed',
      desc: '',
      args: [error],
    );
  }

  /// `Retry analysis failed: {error}`
  String menu_vision_error_retry_failed(Object error) {
    return Intl.message(
      'Retry analysis failed: $error',
      name: 'menu_vision_error_retry_failed',
      desc: '',
      args: [error],
    );
  }

  /// `AI Menu Visual Translation`
  String get menu_vision_title {
    return Intl.message(
      'AI Menu Visual Translation',
      name: 'menu_vision_title',
      desc: '',
      args: [],
    );
  }

  /// `Take photo`
  String get menu_vision_tooltip_camera {
    return Intl.message(
      'Take photo',
      name: 'menu_vision_tooltip_camera',
      desc: '',
      args: [],
    );
  }

  /// `Choose from gallery`
  String get menu_vision_tooltip_gallery {
    return Intl.message(
      'Choose from gallery',
      name: 'menu_vision_tooltip_gallery',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get menu_vision_tooltip_close {
    return Intl.message(
      'Close',
      name: 'menu_vision_tooltip_close',
      desc: '',
      args: [],
    );
  }

  /// `Snap Menu, AI Recognizes Instantly`
  String get menu_vision_prompt_title {
    return Intl.message(
      'Snap Menu, AI Recognizes Instantly',
      name: 'menu_vision_prompt_title',
      desc: '',
      args: [],
    );
  }

  /// `Supports cross-border menu translation, ingredient breakdown, allergen alerts, and spiciness analysis`
  String get menu_vision_prompt_subtitle {
    return Intl.message(
      'Supports cross-border menu translation, ingredient breakdown, allergen alerts, and spiciness analysis',
      name: 'menu_vision_prompt_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Take Photo to Recognize`
  String get menu_vision_btn_camera {
    return Intl.message(
      'Take Photo to Recognize',
      name: 'menu_vision_btn_camera',
      desc: '',
      args: [],
    );
  }

  /// `Choose from Gallery`
  String get menu_vision_btn_gallery {
    return Intl.message(
      'Choose from Gallery',
      name: 'menu_vision_btn_gallery',
      desc: '',
      args: [],
    );
  }

  /// `Gemini is analyzing the menu...`
  String get menu_vision_loading_title {
    return Intl.message(
      'Gemini is analyzing the menu...',
      name: 'menu_vision_loading_title',
      desc: '',
      args: [],
    );
  }

  /// `Translating dishes, marking allergens, and breaking down ingredients. Takes a few seconds`
  String get menu_vision_loading_subtitle {
    return Intl.message(
      'Translating dishes, marking allergens, and breaking down ingredients. Takes a few seconds',
      name: 'menu_vision_loading_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `No dish items recognized. Please ensure photo is clear and try again`
  String get menu_vision_empty_dishes {
    return Intl.message(
      'No dish items recognized. Please ensure photo is clear and try again',
      name: 'menu_vision_empty_dishes',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get menu_vision_tab_all {
    return Intl.message('All', name: 'menu_vision_tab_all', desc: '', args: []);
  }

  /// `Recognition Failed`
  String get menu_vision_failure_title {
    return Intl.message(
      'Recognition Failed',
      name: 'menu_vision_failure_title',
      desc: '',
      args: [],
    );
  }

  /// `Retry this photo`
  String get menu_vision_btn_retry_photo {
    return Intl.message(
      'Retry this photo',
      name: 'menu_vision_btn_retry_photo',
      desc: '',
      args: [],
    );
  }

  /// `Retake`
  String get menu_vision_btn_retake {
    return Intl.message(
      'Retake',
      name: 'menu_vision_btn_retake',
      desc: '',
      args: [],
    );
  }

  /// `Choose from gallery`
  String get menu_vision_btn_reselect_gallery {
    return Intl.message(
      'Choose from gallery',
      name: 'menu_vision_btn_reselect_gallery',
      desc: '',
      args: [],
    );
  }

  /// `Photo selection cancelled`
  String get menu_vision_cancelled_title {
    return Intl.message(
      'Photo selection cancelled',
      name: 'menu_vision_cancelled_title',
      desc: '',
      args: [],
    );
  }

  /// `Whenever you are ready, click below to start`
  String get menu_vision_cancelled_subtitle {
    return Intl.message(
      'Whenever you are ready, click below to start',
      name: 'menu_vision_cancelled_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Camera`
  String get menu_vision_btn_take_photo_short {
    return Intl.message(
      'Camera',
      name: 'menu_vision_btn_take_photo_short',
      desc: '',
      args: [],
    );
  }

  /// `Gallery`
  String get menu_vision_btn_gallery_short {
    return Intl.message(
      'Gallery',
      name: 'menu_vision_btn_gallery_short',
      desc: '',
      args: [],
    );
  }

  /// `Spiciness: `
  String get dish_card_spice_level_prefix {
    return Intl.message(
      'Spiciness: ',
      name: 'dish_card_spice_level_prefix',
      desc: '',
      args: [],
    );
  }

  /// `Main Ingredients: `
  String get dish_card_ingredients_prefix {
    return Intl.message(
      'Main Ingredients: ',
      name: 'dish_card_ingredients_prefix',
      desc: '',
      args: [],
    );
  }

  /// `AI Menu Vision Recognition`
  String get restaurant_detail_menu_vision_tooltip {
    return Intl.message(
      'AI Menu Vision Recognition',
      name: 'restaurant_detail_menu_vision_tooltip',
      desc: '',
      args: [],
    );
  }

  /// `Loading...`
  String get loading {
    return Intl.message('Loading...', name: 'loading', desc: '', args: []);
  }

  /// `Account not found or not registered, please try again`
  String get auth_error_user_not_found {
    return Intl.message(
      'Account not found or not registered, please try again',
      name: 'auth_error_user_not_found',
      desc: '',
      args: [],
    );
  }

  /// `Incorrect password, please try again`
  String get auth_error_wrong_password {
    return Intl.message(
      'Incorrect password, please try again',
      name: 'auth_error_wrong_password',
      desc: '',
      args: [],
    );
  }

  /// `Password security is low, please use another character combination`
  String get auth_error_weak_password {
    return Intl.message(
      'Password security is low, please use another character combination',
      name: 'auth_error_weak_password',
      desc: '',
      args: [],
    );
  }

  /// `Email already registered, please use another email to register`
  String get auth_error_email_already_in_use {
    return Intl.message(
      'Email already registered, please use another email to register',
      name: 'auth_error_email_already_in_use',
      desc: '',
      args: [],
    );
  }

  /// `Invalid email, please enter again`
  String get auth_error_invalid_email {
    return Intl.message(
      'Invalid email, please enter again',
      name: 'auth_error_invalid_email',
      desc: '',
      args: [],
    );
  }

  /// `Email not verified yet. Please check your verification email before signing in`
  String get auth_error_email_not_verified {
    return Intl.message(
      'Email not verified yet. Please check your verification email before signing in',
      name: 'auth_error_email_not_verified',
      desc: '',
      args: [],
    );
  }

  /// `An account already exists with a different credential. Please sign in using the original provider`
  String get auth_error_account_exists_different_credential {
    return Intl.message(
      'An account already exists with a different credential. Please sign in using the original provider',
      name: 'auth_error_account_exists_different_credential',
      desc: '',
      args: [],
    );
  }

  /// `Biometric authentication failed, please try again`
  String get auth_error_biometric_failed {
    return Intl.message(
      'Biometric authentication failed, please try again',
      name: 'auth_error_biometric_failed',
      desc: '',
      args: [],
    );
  }

  /// `Sign in failed, please try again`
  String get auth_error_sign_in_failed {
    return Intl.message(
      'Sign in failed, please try again',
      name: 'auth_error_sign_in_failed',
      desc: '',
      args: [],
    );
  }

  /// `Please authenticate to sign in`
  String get biometric_prompt_reason {
    return Intl.message(
      'Please authenticate to sign in',
      name: 'biometric_prompt_reason',
      desc: '',
      args: [],
    );
  }

  /// `Appetizer`
  String get dish_category_appetizer {
    return Intl.message(
      'Appetizer',
      name: 'dish_category_appetizer',
      desc: '',
      args: [],
    );
  }

  /// `Main`
  String get dish_category_main {
    return Intl.message('Main', name: 'dish_category_main', desc: '', args: []);
  }

  /// `Soup`
  String get dish_category_soup {
    return Intl.message('Soup', name: 'dish_category_soup', desc: '', args: []);
  }

  /// `Dessert`
  String get dish_category_dessert {
    return Intl.message(
      'Dessert',
      name: 'dish_category_dessert',
      desc: '',
      args: [],
    );
  }

  /// `Beverage`
  String get dish_category_beverage {
    return Intl.message(
      'Beverage',
      name: 'dish_category_beverage',
      desc: '',
      args: [],
    );
  }

  /// `Other`
  String get dish_category_other {
    return Intl.message(
      'Other',
      name: 'dish_category_other',
      desc: '',
      args: [],
    );
  }

  /// `Contains`
  String get allergen_risk_contains {
    return Intl.message(
      'Contains',
      name: 'allergen_risk_contains',
      desc: '',
      args: [],
    );
  }

  /// `May Contain`
  String get allergen_risk_may_contain {
    return Intl.message(
      'May Contain',
      name: 'allergen_risk_may_contain',
      desc: '',
      args: [],
    );
  }

  /// `Free`
  String get allergen_risk_none {
    return Intl.message('Free', name: 'allergen_risk_none', desc: '', args: []);
  }

  /// `Monday`
  String get weekday_monday {
    return Intl.message('Monday', name: 'weekday_monday', desc: '', args: []);
  }

  /// `Tuesday`
  String get weekday_tuesday {
    return Intl.message('Tuesday', name: 'weekday_tuesday', desc: '', args: []);
  }

  /// `Wednesday`
  String get weekday_wednesday {
    return Intl.message(
      'Wednesday',
      name: 'weekday_wednesday',
      desc: '',
      args: [],
    );
  }

  /// `Thursday`
  String get weekday_thursday {
    return Intl.message(
      'Thursday',
      name: 'weekday_thursday',
      desc: '',
      args: [],
    );
  }

  /// `Friday`
  String get weekday_friday {
    return Intl.message('Friday', name: 'weekday_friday', desc: '', args: []);
  }

  /// `Saturday`
  String get weekday_saturday {
    return Intl.message(
      'Saturday',
      name: 'weekday_saturday',
      desc: '',
      args: [],
    );
  }

  /// `Sunday`
  String get weekday_sunday {
    return Intl.message('Sunday', name: 'weekday_sunday', desc: '', args: []);
  }

  /// `AI Review Intelligence`
  String get review_summary_title {
    return Intl.message(
      'AI Review Intelligence',
      name: 'review_summary_title',
      desc: '',
      args: [],
    );
  }

  /// `Pros`
  String get review_summary_pros {
    return Intl.message(
      'Pros',
      name: 'review_summary_pros',
      desc: '',
      args: [],
    );
  }

  /// `Considerations`
  String get review_summary_cons {
    return Intl.message(
      'Considerations',
      name: 'review_summary_cons',
      desc: '',
      args: [],
    );
  }

  /// `Highlights`
  String get review_summary_highlights {
    return Intl.message(
      'Highlights',
      name: 'review_summary_highlights',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get review_summary_retry {
    return Intl.message(
      'Retry',
      name: 'review_summary_retry',
      desc: '',
      args: [],
    );
  }

  /// `Failed to generate AI review summary`
  String get review_summary_failed {
    return Intl.message(
      'Failed to generate AI review summary',
      name: 'review_summary_failed',
      desc: '',
      args: [],
    );
  }

  /// `No review summary available`
  String get review_summary_empty {
    return Intl.message(
      'No review summary available',
      name: 'review_summary_empty',
      desc: '',
      args: [],
    );
  }

  /// `Open in Yelp`
  String get open_in_yelp {
    return Intl.message(
      'Open in Yelp',
      name: 'open_in_yelp',
      desc: '',
      args: [],
    );
  }

  /// `Suggestions`
  String get autocomplete_suggestions_title {
    return Intl.message(
      'Suggestions',
      name: 'autocomplete_suggestions_title',
      desc: '',
      args: [],
    );
  }

  /// `Businesses`
  String get autocomplete_businesses_title {
    return Intl.message(
      'Businesses',
      name: 'autocomplete_businesses_title',
      desc: '',
      args: [],
    );
  }

  /// `Categories`
  String get autocomplete_categories_title {
    return Intl.message(
      'Categories',
      name: 'autocomplete_categories_title',
      desc: '',
      args: [],
    );
  }

  /// `No suggestions found`
  String get autocomplete_no_results {
    return Intl.message(
      'No suggestions found',
      name: 'autocomplete_no_results',
      desc: '',
      args: [],
    );
  }

  /// `Search restaurants, cuisines...`
  String get autocomplete_search_hint {
    return Intl.message(
      'Search restaurants, cuisines...',
      name: 'autocomplete_search_hint',
      desc: '',
      args: [],
    );
  }

  /// `Foodie Notes`
  String get notes_feed_title {
    return Intl.message(
      'Foodie Notes',
      name: 'notes_feed_title',
      desc: '',
      args: [],
    );
  }

  /// `No foodie notes yet`
  String get notes_feed_empty {
    return Intl.message(
      'No foodie notes yet',
      name: 'notes_feed_empty',
      desc: '',
      args: [],
    );
  }

  /// `Note Detail`
  String get note_detail_title {
    return Intl.message(
      'Note Detail',
      name: 'note_detail_title',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load video`
  String get note_video_error {
    return Intl.message(
      'Failed to load video',
      name: 'note_video_error',
      desc: '',
      args: [],
    );
  }

  /// `View Restaurant Details`
  String get note_restaurant_sheet_view_detail {
    return Intl.message(
      'View Restaurant Details',
      name: 'note_restaurant_sheet_view_detail',
      desc: '',
      args: [],
    );
  }

  /// `Navigate with Google Maps`
  String get note_restaurant_sheet_open_maps {
    return Intl.message(
      'Navigate with Google Maps',
      name: 'note_restaurant_sheet_open_maps',
      desc: '',
      args: [],
    );
  }

  /// `This note isn't linked to a restaurant profile yet. You can still navigate via Google Maps.`
  String get note_restaurant_sheet_unlinked_hint {
    return Intl.message(
      'This note isn\'t linked to a restaurant profile yet. You can still navigate via Google Maps.',
      name: 'note_restaurant_sheet_unlinked_hint',
      desc: '',
      args: [],
    );
  }

  /// `Unable to load restaurant summary`
  String get note_restaurant_sheet_error {
    return Intl.message(
      'Unable to load restaurant summary',
      name: 'note_restaurant_sheet_error',
      desc: '',
      args: [],
    );
  }

  /// `Food Maps`
  String get food_maps_title {
    return Intl.message(
      'Food Maps',
      name: 'food_maps_title',
      desc: '',
      args: [],
    );
  }

  /// `No collaborative food maps yet`
  String get food_maps_empty_title {
    return Intl.message(
      'No collaborative food maps yet',
      name: 'food_maps_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `Create a themed food map or enter a friend's invite code to collaborate`
  String get food_maps_empty_subtitle {
    return Intl.message(
      'Create a themed food map or enter a friend\'s invite code to collaborate',
      name: 'food_maps_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Create Map`
  String get food_maps_create_action {
    return Intl.message(
      'Create Map',
      name: 'food_maps_create_action',
      desc: '',
      args: [],
    );
  }

  /// `Join with Code`
  String get food_maps_join_action {
    return Intl.message(
      'Join with Code',
      name: 'food_maps_join_action',
      desc: '',
      args: [],
    );
  }

  /// `Create Collaborative Map`
  String get food_maps_create_dialog_title {
    return Intl.message(
      'Create Collaborative Map',
      name: 'food_maps_create_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `Map Name`
  String get food_maps_name_label {
    return Intl.message(
      'Map Name',
      name: 'food_maps_name_label',
      desc: '',
      args: [],
    );
  }

  /// `e.g. Late Night Ramen Spots`
  String get food_maps_name_hint {
    return Intl.message(
      'e.g. Late Night Ramen Spots',
      name: 'food_maps_name_hint',
      desc: '',
      args: [],
    );
  }

  /// `Description (optional)`
  String get food_maps_description_label {
    return Intl.message(
      'Description (optional)',
      name: 'food_maps_description_label',
      desc: '',
      args: [],
    );
  }

  /// `Briefly describe this food map`
  String get food_maps_description_hint {
    return Intl.message(
      'Briefly describe this food map',
      name: 'food_maps_description_hint',
      desc: '',
      args: [],
    );
  }

  /// `Join Food Map`
  String get food_maps_join_dialog_title {
    return Intl.message(
      'Join Food Map',
      name: 'food_maps_join_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `8-Character Invite Code`
  String get food_maps_invite_code_label {
    return Intl.message(
      '8-Character Invite Code',
      name: 'food_maps_invite_code_label',
      desc: '',
      args: [],
    );
  }

  /// `Enter invite code from a friend`
  String get food_maps_invite_code_hint {
    return Intl.message(
      'Enter invite code from a friend',
      name: 'food_maps_invite_code_hint',
      desc: '',
      args: [],
    );
  }

  /// `Copy Invite Code`
  String get food_maps_copy_code_tooltip {
    return Intl.message(
      'Copy Invite Code',
      name: 'food_maps_copy_code_tooltip',
      desc: '',
      args: [],
    );
  }

  /// `Invite code copied: {code}`
  String food_maps_code_copied(Object code) {
    return Intl.message(
      'Invite code copied: $code',
      name: 'food_maps_code_copied',
      desc: '',
      args: [code],
    );
  }

  /// `Owner`
  String get food_maps_owner_badge {
    return Intl.message(
      'Owner',
      name: 'food_maps_owner_badge',
      desc: '',
      args: [],
    );
  }

  /// `{count} members`
  String food_maps_member_count(Object count) {
    return Intl.message(
      '$count members',
      name: 'food_maps_member_count',
      desc: '',
      args: [count],
    );
  }

  /// `{count} restaurants`
  String food_maps_item_count(Object count) {
    return Intl.message(
      '$count restaurants',
      name: 'food_maps_item_count',
      desc: '',
      args: [count],
    );
  }

  /// `Delete Map`
  String get food_maps_delete_map {
    return Intl.message(
      'Delete Map',
      name: 'food_maps_delete_map',
      desc: '',
      args: [],
    );
  }

  /// `Delete "{title}"? All recommendations and votes will be permanently removed.`
  String food_maps_delete_confirm(Object title) {
    return Intl.message(
      'Delete "$title"? All recommendations and votes will be permanently removed.',
      name: 'food_maps_delete_confirm',
      desc: '',
      args: [title],
    );
  }

  /// `Leave Map`
  String get food_maps_leave_map {
    return Intl.message(
      'Leave Map',
      name: 'food_maps_leave_map',
      desc: '',
      args: [],
    );
  }

  /// `Leave "{title}"?`
  String food_maps_leave_confirm(Object title) {
    return Intl.message(
      'Leave "$title"?',
      name: 'food_maps_leave_confirm',
      desc: '',
      args: [title],
    );
  }

  /// `Created map "{title}"`
  String food_maps_created_success(Object title) {
    return Intl.message(
      'Created map "$title"',
      name: 'food_maps_created_success',
      desc: '',
      args: [title],
    );
  }

  /// `Joined map "{title}"`
  String food_maps_joined_success(Object title) {
    return Intl.message(
      'Joined map "$title"',
      name: 'food_maps_joined_success',
      desc: '',
      args: [title],
    );
  }

  /// `You are already in "{title}"`
  String food_maps_already_member(Object title) {
    return Intl.message(
      'You are already in "$title"',
      name: 'food_maps_already_member',
      desc: '',
      args: [title],
    );
  }

  /// `Food map deleted`
  String get food_maps_deleted_success {
    return Intl.message(
      'Food map deleted',
      name: 'food_maps_deleted_success',
      desc: '',
      args: [],
    );
  }

  /// `Left food map`
  String get food_maps_left_success {
    return Intl.message(
      'Left food map',
      name: 'food_maps_left_success',
      desc: '',
      args: [],
    );
  }

  /// `No restaurants yet. Add from restaurant details or import from favorites!`
  String get food_maps_detail_empty {
    return Intl.message(
      'No restaurants yet. Add from restaurant details or import from favorites!',
      name: 'food_maps_detail_empty',
      desc: '',
      args: [],
    );
  }

  /// `Recommended by {name}`
  String food_maps_recommended_by(Object name) {
    return Intl.message(
      'Recommended by $name',
      name: 'food_maps_recommended_by',
      desc: '',
      args: [name],
    );
  }

  /// `Edit Recommendation Note`
  String get food_maps_edit_note {
    return Intl.message(
      'Edit Recommendation Note',
      name: 'food_maps_edit_note',
      desc: '',
      args: [],
    );
  }

  /// `Recommendation Note (optional)`
  String get food_maps_note_label {
    return Intl.message(
      'Recommendation Note (optional)',
      name: 'food_maps_note_label',
      desc: '',
      args: [],
    );
  }

  /// `Share must-order dishes or tips...`
  String get food_maps_note_hint {
    return Intl.message(
      'Share must-order dishes or tips...',
      name: 'food_maps_note_hint',
      desc: '',
      args: [],
    );
  }

  /// `Recommendation note updated`
  String get food_maps_note_updated {
    return Intl.message(
      'Recommendation note updated',
      name: 'food_maps_note_updated',
      desc: '',
      args: [],
    );
  }

  /// `Remove Restaurant`
  String get food_maps_remove_restaurant {
    return Intl.message(
      'Remove Restaurant',
      name: 'food_maps_remove_restaurant',
      desc: '',
      args: [],
    );
  }

  /// `Remove "{name}" from this map?`
  String food_maps_remove_restaurant_confirm(Object name) {
    return Intl.message(
      'Remove "$name" from this map?',
      name: 'food_maps_remove_restaurant_confirm',
      desc: '',
      args: [name],
    );
  }

  /// `Restaurant removed`
  String get food_maps_restaurant_removed {
    return Intl.message(
      'Restaurant removed',
      name: 'food_maps_restaurant_removed',
      desc: '',
      args: [],
    );
  }

  /// `No restaurants with coordinates yet. Switch back to list view.`
  String get food_maps_no_coordinates {
    return Intl.message(
      'No restaurants with coordinates yet. Switch back to list view.',
      name: 'food_maps_no_coordinates',
      desc: '',
      args: [],
    );
  }

  /// `Map View`
  String get food_maps_toggle_map_view {
    return Intl.message(
      'Map View',
      name: 'food_maps_toggle_map_view',
      desc: '',
      args: [],
    );
  }

  /// `List View`
  String get food_maps_toggle_list_view {
    return Intl.message(
      'List View',
      name: 'food_maps_toggle_list_view',
      desc: '',
      args: [],
    );
  }

  /// `Add to Food Map`
  String get food_maps_add_to_map_tooltip {
    return Intl.message(
      'Add to Food Map',
      name: 'food_maps_add_to_map_tooltip',
      desc: '',
      args: [],
    );
  }

  /// `Add to Collaborative Map`
  String get food_maps_add_sheet_title {
    return Intl.message(
      'Add to Collaborative Map',
      name: 'food_maps_add_sheet_title',
      desc: '',
      args: [],
    );
  }

  /// `Create New Map & Add`
  String get food_maps_add_sheet_create_new {
    return Intl.message(
      'Create New Map & Add',
      name: 'food_maps_add_sheet_create_new',
      desc: '',
      args: [],
    );
  }

  /// `Add to Selected Map`
  String get food_maps_add_sheet_submit {
    return Intl.message(
      'Add to Selected Map',
      name: 'food_maps_add_sheet_submit',
      desc: '',
      args: [],
    );
  }

  /// `Added to "{title}"`
  String food_maps_added_success(Object title) {
    return Intl.message(
      'Added to "$title"',
      name: 'food_maps_added_success',
      desc: '',
      args: [title],
    );
  }

  /// `Already in "{title}"`
  String food_maps_already_in_map(Object title) {
    return Intl.message(
      'Already in "$title"',
      name: 'food_maps_already_in_map',
      desc: '',
      args: [title],
    );
  }

  /// `Import Favorites`
  String get food_maps_import_favorites_action {
    return Intl.message(
      'Import Favorites',
      name: 'food_maps_import_favorites_action',
      desc: '',
      args: [],
    );
  }

  /// `Import from Favorites`
  String get food_maps_import_favorites_title {
    return Intl.message(
      'Import from Favorites',
      name: 'food_maps_import_favorites_title',
      desc: '',
      args: [],
    );
  }

  /// `No favorite restaurants available to import`
  String get food_maps_import_favorites_empty {
    return Intl.message(
      'No favorite restaurants available to import',
      name: 'food_maps_import_favorites_empty',
      desc: '',
      args: [],
    );
  }

  /// `Already added`
  String get food_maps_import_already_added {
    return Intl.message(
      'Already added',
      name: 'food_maps_import_already_added',
      desc: '',
      args: [],
    );
  }

  /// `Import Selected ({count})`
  String food_maps_import_submit(Object count) {
    return Intl.message(
      'Import Selected ($count)',
      name: 'food_maps_import_submit',
      desc: '',
      args: [count],
    );
  }

  /// `Imported {added} restaurants`
  String food_maps_import_success(Object added) {
    return Intl.message(
      'Imported $added restaurants',
      name: 'food_maps_import_success',
      desc: '',
      args: [added],
    );
  }

  /// `Please check your input and character limits`
  String get food_maps_error_invalid_input {
    return Intl.message(
      'Please check your input and character limits',
      name: 'food_maps_error_invalid_input',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a valid 8-character invite code`
  String get food_maps_error_invalid_invite_code {
    return Intl.message(
      'Please enter a valid 8-character invite code',
      name: 'food_maps_error_invalid_invite_code',
      desc: '',
      args: [],
    );
  }

  /// `Food map or invite code not found`
  String get food_maps_error_map_not_found {
    return Intl.message(
      'Food map or invite code not found',
      name: 'food_maps_error_map_not_found',
      desc: '',
      args: [],
    );
  }

  /// `This restaurant is no longer in the map`
  String get food_maps_error_item_not_found {
    return Intl.message(
      'This restaurant is no longer in the map',
      name: 'food_maps_error_item_not_found',
      desc: '',
      args: [],
    );
  }

  /// `You do not have permission for this action`
  String get food_maps_error_permission_denied {
    return Intl.message(
      'You do not have permission for this action',
      name: 'food_maps_error_permission_denied',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong, please try again`
  String get food_maps_error_generic {
    return Intl.message(
      'Something went wrong, please try again',
      name: 'food_maps_error_generic',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
