import '../../../domain/entities/entities_barrel.dart';
import '../../../generated/l10n.dart';

extension AuthFailureL10n on AuthFailureReason {
  String get localizedMessage => switch (this) {
    AuthFailureReason.userNotFound => S.current.auth_error_user_not_found,
    AuthFailureReason.wrongPassword => S.current.auth_error_wrong_password,
    AuthFailureReason.weakPassword => S.current.auth_error_weak_password,
    AuthFailureReason.emailAlreadyInUse =>
      S.current.auth_error_email_already_in_use,
    AuthFailureReason.invalidEmail => S.current.auth_error_invalid_email,
    AuthFailureReason.emailNotVerified =>
      S.current.auth_error_email_not_verified,
    AuthFailureReason.accountExistsWithDifferentCredential =>
      S.current.auth_error_account_exists_different_credential,
    AuthFailureReason.biometricFailed => S.current.auth_error_biometric_failed,
    AuthFailureReason.signInFailed => S.current.auth_error_sign_in_failed,
    AuthFailureReason.unknown => S.current.error_and_retry,
  };
}
