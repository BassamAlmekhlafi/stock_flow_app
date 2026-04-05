import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/interfaces/auth_repository_interface.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/backup_service.dart';
import '../../home/controllers/home_controller.dart';

class SettingsController extends GetxController {
  final IAuthRepository authRepo;
  late final BackupService backupService;

  SettingsController({required this.authRepo});

  var isAppLocked = false.obs;
  var isFingerprintEnabled = false.obs;
  var expiryAlertDays = 30.obs;

  @override
  void onInit() {
    super.onInit();
    backupService = Get.put(BackupService());
    loadSettings();
  }

  Future<void> loadSettings() async {
    isAppLocked.value = await authRepo.isAppLocked();
    isFingerprintEnabled.value = await authRepo.isFingerprintEnabled();
    expiryAlertDays.value = await authRepo.getExpiryAlertDays();
  }

  Future<void> updateExpiryAlertDays(int days) async {
    await authRepo.setExpiryAlertDays(days);
    expiryAlertDays.value = days;
    
    // Update HomeController if it's registered so HomeView reacts instantly
    if (Get.isRegistered<HomeController>()) {
      final homeCtrl = Get.find<HomeController>();
      homeCtrl.expiryAlertDays.value = days;
      homeCtrl.items.refresh(); // Force list items to re-evaluate their status indicators
    }
  }

  Future<void> toggleAppLock(bool value) async {
    if (value) {
      _showSetPasswordDialog();
    } else {
      await authRepo.setAppLocked(false);
      isAppLocked.value = false;
      isFingerprintEnabled.value = false;
      await authRepo.setFingerprintEnabled(false);
    }
  }

  Future<void> toggleFingerprint(bool value) async {
    if (value && !isAppLocked.value) {
      Get.snackbar('تنبيه', 'يجب تفعيل قفل التطبيق أولاً لاستخدام البصمة', 
      backgroundColor: AppColors.storeYellow, colorText: AppColors.textDark);
      return;
    }
    await authRepo.setFingerprintEnabled(value);
    isFingerprintEnabled.value = value;
  }

  Future<void> createBackup() async {
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      barrierDismissible: false,
    );

    final success = await backupService.exportDatabase();
    Get.back(); // close dialog

    if (success) {
      Get.snackbar('نسخ احتياطي', 'تم حفظ النسخة الاحتياطية بنجاح.',
          backgroundColor: AppColors.systemGreen, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('خطأ', 'لم يتم حفظ النسخة الاحتياطية. إما بسبب الإلغاء أو خطأ في النظام.',
          backgroundColor: AppColors.stockRed, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> restoreBackup() async {
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      barrierDismissible: false,
    );

    final success = await backupService.importDatabase();
    Get.back(); // close dialog

    if (success) {
      Get.snackbar('استعادة', 'تم استعادة النسخة الاحتياطية بنجاح.',
          backgroundColor: AppColors.systemGreen, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      
      // Reload items in HomeController
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadItems();
      }
    } else {
      Get.snackbar('خطأ', 'تعذرت الاستعادة. تأكد من صحة الملف المختار.',
          backgroundColor: AppColors.stockRed, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _showSetPasswordDialog() {
    final TextEditingController passController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        scrollable: true,
        title: const Center(
          child: Text(
            'إعداد كلمة مرور',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: AppColors.primary,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'يرجى إدخال كلمة مرور قوية لحماية بياناتك',
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                prefixIcon: const Icon(Icons.lock_outline),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (passController.text.isEmpty ||
                        passController.text != confirmController.text) {
                      Get.snackbar(
                        'تحذير',
                        'كلمات المرور غير متطابقة أو فارغة',
                        backgroundColor: AppColors.stockRed,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.TOP,
                      );
                      return;
                    }
                    await authRepo.setPassword(passController.text);
                    await authRepo.setAppLocked(true);
                    isAppLocked.value = true;
                    Get.back();
                    Get.snackbar(
                      'تم التفعيل',
                      'تم تفعيل قفل التطبيق بنجاح',
                      backgroundColor: AppColors.systemGreen,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.TOP,
                    );
                  },
                  child: const Text(
                    'تفعيل القفل',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
