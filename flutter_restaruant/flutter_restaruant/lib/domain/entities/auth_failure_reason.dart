enum AuthFailureReason {
  userNotFound,
  wrongPassword,
  weakPassword,
  emailAlreadyInUse,
  invalidEmail,
  emailNotVerified,
  accountExistsWithDifferentCredential,
  biometricFailed,
  signInFailed,
  unknown;
}
