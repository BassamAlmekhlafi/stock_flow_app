import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import '../../../data/interfaces/auth_repository_interface.dart';
import '../../../core/constants/app_routes.dart';

class AuthController extends GetxController {
  final IAuthRepository authRepo;
  AuthController({required this.authRepo});

  var isPasswordVisible = false.obs;
  var passwordError = ''.obs;
  var isFingerprintEnabled = false.obs;

  final LocalAuthentication auth = LocalAuthentication();

  @override
  void onInit() {
    super.onInit();
    checkInitialAuth();
  }

  Future<void> checkInitialAuth() async {
    final isLocked = await authRepo.isAppLocked();
    if (!isLocked) {
      Get.offAllNamed(AppRoutes.HOME);
      return;
    }

    isFingerprintEnabled.value = await authRepo.isFingerprintEnabled();
    if (isFingerprintEnabled.value) {
      await authenticateWithFingerprint();
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> loginWithPassword(String inputPassword) async {
    final savedPassword = await authRepo.getPassword();
    if (savedPassword == inputPassword) {
      passwordError.value = '';
      Get.offAllNamed(AppRoutes.HOME);
    } else {
      passwordError.value = 'كلمة المرور غير صحيحة';
    }
  }

  Future<void> authenticateWithFingerprint() async {
    if (!isFingerprintEnabled.value) return;

    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (canAuthenticate) {
        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'يرجى المصادقة للدخول إلى مخزوني',
        );
        if (didAuthenticate) {
          Get.offAllNamed(AppRoutes.HOME);
        }
      }
    } catch (e) {
      Get.snackbar('تنبيه', 'تعذر استخدام البصمة');
    }
  }
}
