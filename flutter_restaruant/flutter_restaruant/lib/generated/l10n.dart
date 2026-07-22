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

  /// `Phone:`
  String get store_phone {
    return Intl.message('Phone:', name: 'store_phone', desc: '', args: []);
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
