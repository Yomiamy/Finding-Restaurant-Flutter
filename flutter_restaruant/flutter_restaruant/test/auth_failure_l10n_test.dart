import 'dart:ui';

import 'package:flutter_restaruant/domain/entities/entities_barrel.dart';
import 'package:flutter_restaruant/flow/signinup/view/auth_failure_l10n_extension.dart';
import 'package:flutter_restaruant/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthFailureL10n Extension Tests', () {
    test('zh_TW localization for all AuthFailureReason variants', () async {
      await S.load(const Locale('zh', 'TW'));

      expect(
        AuthFailureReason.userNotFound.localizedMessage,
        '帳號輸入錯誤或尚未註冊，請再試一次',
      );
      expect(
        AuthFailureReason.wrongPassword.localizedMessage,
        '密碼錯誤，請再試一次',
      );
      expect(
        AuthFailureReason.weakPassword.localizedMessage,
        '密碼強度不足，請使用其他字元組合',
      );
      expect(
        AuthFailureReason.emailAlreadyInUse.localizedMessage,
        '此 Email 已被註冊，請使用其他 Email 註冊',
      );
      expect(
        AuthFailureReason.invalidEmail.localizedMessage,
        '無效的 Email，請重新輸入',
      );
      expect(
        AuthFailureReason.emailNotVerified.localizedMessage,
        'Email 尚未驗證，請使用驗證信驗證後再登入',
      );
      expect(
        AuthFailureReason.accountExistsWithDifferentCredential.localizedMessage,
        '此帳號已使用其他登入方式，請使用原始登入方式',
      );
      expect(
        AuthFailureReason.biometricFailed.localizedMessage,
        '生物識別認證失敗，請重新登入一次',
      );
      expect(
        AuthFailureReason.signInFailed.localizedMessage,
        '登入失敗，請再試一次',
      );
      expect(
        AuthFailureReason.unknown.localizedMessage,
        S.current.error_and_retry,
      );
    });

    test('en localization for all AuthFailureReason variants', () async {
      await S.load(const Locale('en'));

      expect(
        AuthFailureReason.userNotFound.localizedMessage,
        'Account not found or not registered, please try again',
      );
      expect(
        AuthFailureReason.wrongPassword.localizedMessage,
        'Incorrect password, please try again',
      );
      expect(
        AuthFailureReason.weakPassword.localizedMessage,
        'Password security is low, please use another character combination',
      );
      expect(
        AuthFailureReason.emailAlreadyInUse.localizedMessage,
        'Email already registered, please use another email to register',
      );
      expect(
        AuthFailureReason.invalidEmail.localizedMessage,
        'Invalid email, please enter again',
      );
      expect(
        AuthFailureReason.emailNotVerified.localizedMessage,
        'Email not verified yet. Please check your verification email before signing in',
      );
      expect(
        AuthFailureReason.accountExistsWithDifferentCredential.localizedMessage,
        'An account already exists with a different credential. Please sign in using the original provider',
      );
      expect(
        AuthFailureReason.biometricFailed.localizedMessage,
        'Biometric authentication failed, please try again',
      );
      expect(
        AuthFailureReason.signInFailed.localizedMessage,
        'Sign in failed, please try again',
      );
      expect(
        AuthFailureReason.unknown.localizedMessage,
        S.current.error_and_retry,
      );
    });
  });

  group('RestaurantBusinessTimeEntity getWeekDayStrByIndex Tests', () {
    test('zh_TW weekdays', () async {
      await S.load(const Locale('zh', 'TW'));

      expect(RestaurantBusinessTimeEntity.getWeekDayStrByIndex(0), '星期一');
      expect(RestaurantBusinessTimeEntity.getWeekDayStrByIndex(1), '星期二');
      expect(RestaurantBusinessTimeEntity.getWeekDayStrByIndex(2), '星期三');
      expect(RestaurantBusinessTimeEntity.getWeekDayStrByIndex(3), '星期四');
      expect(RestaurantBusinessTimeEntity.getWeekDayStrByIndex(4), '星期五');
      expect(RestaurantBusinessTimeEntity.getWeekDayStrByIndex(5), '星期六');
      expect(RestaurantBusinessTimeEntity.getWeekDayStrByIndex(6), '星期日');
      expect(RestaurantBusinessTimeEntity.getWeekDayStrByIndex(7), '');
    });

    test('en weekdays', () async {
      await S.load(const Locale('en'));

      expect(RestaurantBusinessTimeEntity.getWeekDayStrByIndex(0), 'Monday');
      expect(RestaurantBusinessTimeEntity.getWeekDayStrByIndex(1), 'Tuesday');
      expect(RestaurantBusinessTimeEntity.getWeekDayStrByIndex(2), 'Wednesday');
      expect(RestaurantBusinessTimeEntity.getWeekDayStrByIndex(3), 'Thursday');
      expect(RestaurantBusinessTimeEntity.getWeekDayStrByIndex(4), 'Friday');
      expect(RestaurantBusinessTimeEntity.getWeekDayStrByIndex(5), 'Saturday');
      expect(RestaurantBusinessTimeEntity.getWeekDayStrByIndex(6), 'Sunday');
      expect(RestaurantBusinessTimeEntity.getWeekDayStrByIndex(7), '');
    });
  });
}
