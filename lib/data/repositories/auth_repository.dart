import 'package:shared_preferences/shared_preferences.dart';
import '../interfaces/auth_repository_interface.dart';

class AuthRepository implements IAuthRepository {
  final SharedPreferences prefs;

  AuthRepository(this.prefs);

  static const String _isLockedKey = 'isLocked';
  static const String _passwordKey = 'password';
  static const String _isFingerprintEnabledKey = 'isFingerprint';

  @override
  Future<bool> isAppLocked() async {
    return prefs.getBool(_isLockedKey) ?? false;
  }

  @override
  Future<void> setAppLocked(bool isLocked) async {
    await prefs.setBool(_isLockedKey, isLocked);
  }

  @override
  Future<String?> getPassword() async {
    return prefs.getString(_passwordKey);
  }

  @override
  Future<void> setPassword(String password) async {
    await prefs.setString(_passwordKey, password);
  }

  @override
  Future<bool> isFingerprintEnabled() async {
    return prefs.getBool(_isFingerprintEnabledKey) ?? false;
  }

  @override
  Future<void> setFingerprintEnabled(bool isEnabled) async {
    await prefs.setBool(_isFingerprintEnabledKey, isEnabled);
  }

  @override
  Future<int> getExpiryAlertDays() async {
    return prefs.getInt('expiryAlertDays') ?? 30;
  }

  @override
  Future<void> setExpiryAlertDays(int days) async {
    await prefs.setInt('expiryAlertDays', days);
  }
}
