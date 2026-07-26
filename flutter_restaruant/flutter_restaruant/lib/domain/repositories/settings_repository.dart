abstract interface class SettingsRepository {
  Future<void> logout();

  Future<bool> initBioAuthSetting();

  Future<bool> toggleBioAuthSetting();

  Future<bool> removeAccount(String subject, String bodyPrefix);
}
