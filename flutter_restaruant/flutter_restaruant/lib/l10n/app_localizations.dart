import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @error.
  ///
  /// In zh, this message translates to:
  /// **'錯誤'**
  String get error;

  /// No description provided for @error_and_retry.
  ///
  /// In zh, this message translates to:
  /// **'發生錯誤請再試一次'**
  String get error_and_retry;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'確定'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @apply.
  ///
  /// In zh, this message translates to:
  /// **'套用'**
  String get apply;

  /// No description provided for @filter_rules.
  ///
  /// In zh, this message translates to:
  /// **'過濾條件'**
  String get filter_rules;

  /// No description provided for @filter_price.
  ///
  /// In zh, this message translates to:
  /// **'消費程度'**
  String get filter_price;

  /// No description provided for @filter_business_hour.
  ///
  /// In zh, this message translates to:
  /// **'營業時間'**
  String get filter_business_hour;

  /// No description provided for @filter_sorting_rule.
  ///
  /// In zh, this message translates to:
  /// **'排序依據'**
  String get filter_sorting_rule;

  /// No description provided for @filter_sorting_rule_best_match.
  ///
  /// In zh, this message translates to:
  /// **'最佳配對'**
  String get filter_sorting_rule_best_match;

  /// No description provided for @filter_sorting_rule_distance.
  ///
  /// In zh, this message translates to:
  /// **'距離'**
  String get filter_sorting_rule_distance;

  /// No description provided for @filter_sorting_rating.
  ///
  /// In zh, this message translates to:
  /// **'評分'**
  String get filter_sorting_rating;

  /// No description provided for @filter_sorting_review_count.
  ///
  /// In zh, this message translates to:
  /// **'最多評論'**
  String get filter_sorting_review_count;

  /// No description provided for @main_page_title.
  ///
  /// In zh, this message translates to:
  /// **'尋找餐廳'**
  String get main_page_title;

  /// No description provided for @keyword_search.
  ///
  /// In zh, this message translates to:
  /// **'關鍵字過濾'**
  String get keyword_search;

  /// No description provided for @keyword_search_hint.
  ///
  /// In zh, this message translates to:
  /// **'店名/分類/地區/路'**
  String get keyword_search_hint;

  /// No description provided for @map_my_loc_title.
  ///
  /// In zh, this message translates to:
  /// **'我的位置'**
  String get map_my_loc_title;

  /// No description provided for @photo_viewer_title.
  ///
  /// In zh, this message translates to:
  /// **'預覽'**
  String get photo_viewer_title;

  /// No description provided for @store_phone.
  ///
  /// In zh, this message translates to:
  /// **'電話:'**
  String get store_phone;

  /// No description provided for @review_count_suffix.
  ///
  /// In zh, this message translates to:
  /// **'則評論'**
  String get review_count_suffix;

  /// No description provided for @navigation_choice.
  ///
  /// In zh, this message translates to:
  /// **'請選擇導覽方式'**
  String get navigation_choice;

  /// No description provided for @route_navigation.
  ///
  /// In zh, this message translates to:
  /// **'導航'**
  String get route_navigation;

  /// No description provided for @street_view.
  ///
  /// In zh, this message translates to:
  /// **'街景視圖'**
  String get street_view;

  /// No description provided for @favorite_store_add.
  ///
  /// In zh, this message translates to:
  /// **'新增最愛店家'**
  String get favorite_store_add;

  /// No description provided for @favorite_store_remove.
  ///
  /// In zh, this message translates to:
  /// **'解除最愛店家'**
  String get favorite_store_remove;

  /// No description provided for @business_hour.
  ///
  /// In zh, this message translates to:
  /// **'營業時間'**
  String get business_hour;

  /// No description provided for @settings_title.
  ///
  /// In zh, this message translates to:
  /// **'設定'**
  String get settings_title;

  /// No description provided for @information_section_title.
  ///
  /// In zh, this message translates to:
  /// **'資訊'**
  String get information_section_title;

  /// No description provided for @version_tile_title.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get version_tile_title;

  /// No description provided for @logout_section_title.
  ///
  /// In zh, this message translates to:
  /// **'登出'**
  String get logout_section_title;

  /// No description provided for @delete_account_title.
  ///
  /// In zh, this message translates to:
  /// **'刪除帳戶'**
  String get delete_account_title;

  /// No description provided for @delete_account_email_subject.
  ///
  /// In zh, this message translates to:
  /// **'請求刪除我的帳號及相關數據'**
  String get delete_account_email_subject;

  /// No description provided for @delete_account_email_body.
  ///
  /// In zh, this message translates to:
  /// **'敬愛的團隊，我希望透過這封信來正式請求刪除我的帳號，以及與該帳號相關的所有個人資料和數據。帳號詳細資訊為:'**
  String get delete_account_email_body;

  /// No description provided for @signin_page_title.
  ///
  /// In zh, this message translates to:
  /// **'登入/註冊'**
  String get signin_page_title;

  /// No description provided for @signin_success_msg.
  ///
  /// In zh, this message translates to:
  /// **'登入成功'**
  String get signin_success_msg;

  /// No description provided for @email_signup_success_hint_title.
  ///
  /// In zh, this message translates to:
  /// **'Email帳號建立成功'**
  String get email_signup_success_hint_title;

  /// No description provided for @email_signup_success_hint_msg.
  ///
  /// In zh, this message translates to:
  /// **'帳號建立成功, 請使用Email接收驗證連結並完成驗證'**
  String get email_signup_success_hint_msg;

  /// No description provided for @email_invalid_hint_msg.
  ///
  /// In zh, this message translates to:
  /// **'請輸入正確Email'**
  String get email_invalid_hint_msg;

  /// No description provided for @email_invalid_hint_title.
  ///
  /// In zh, this message translates to:
  /// **'Email帳號'**
  String get email_invalid_hint_title;

  /// No description provided for @passwd_invalid_hint_msg.
  ///
  /// In zh, this message translates to:
  /// **'請輸入密碼'**
  String get passwd_invalid_hint_msg;

  /// No description provided for @passwd_invalid_hint_title.
  ///
  /// In zh, this message translates to:
  /// **'密碼'**
  String get passwd_invalid_hint_title;

  /// No description provided for @signin_btn_title.
  ///
  /// In zh, this message translates to:
  /// **'登入'**
  String get signin_btn_title;

  /// No description provided for @signup_title.
  ///
  /// In zh, this message translates to:
  /// **'註冊新帳號'**
  String get signup_title;

  /// No description provided for @signinup_with_google.
  ///
  /// In zh, this message translates to:
  /// **'使用Google繼續'**
  String get signinup_with_google;

  /// No description provided for @signinup_with_google_hint_msg.
  ///
  /// In zh, this message translates to:
  /// **'Google登入成功'**
  String get signinup_with_google_hint_msg;

  /// No description provided for @signinup_with_fb.
  ///
  /// In zh, this message translates to:
  /// **'使用Facebook繼續'**
  String get signinup_with_fb;

  /// No description provided for @signinup_with_fb_hint_msg.
  ///
  /// In zh, this message translates to:
  /// **'Facebook登入成功'**
  String get signinup_with_fb_hint_msg;

  /// No description provided for @signinup_with_apple.
  ///
  /// In zh, this message translates to:
  /// **'使用Apple繼續'**
  String get signinup_with_apple;

  /// No description provided for @signinup_with_apple_hint_msg.
  ///
  /// In zh, this message translates to:
  /// **'Apple登入成功'**
  String get signinup_with_apple_hint_msg;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
