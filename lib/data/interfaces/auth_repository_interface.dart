abstract class IAuthRepository {
  Future<bool> isAppLocked();
  Future<void> setAppLocked(bool isLocked);
  
  Future<String?> getPassword();
  Future<void> setPassword(String password);
  
  Future<bool> isFingerprintEnabled();
  Future<void> setFingerprintEnabled(bool isEnabled);
  
  Future<int> getExpiryAlertDays();
  Future<void> setExpiryAlertDays(int days);
}
