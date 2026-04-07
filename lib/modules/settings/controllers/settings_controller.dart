import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/interfaces/auth_repository_interface.dart';
import '../../../data/interfaces/item_repository_interface.dart';
import '../../../data/models/item_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/excel_service.dart';
import '../../home/controllers/home_controller.dart';

class SettingsController extends GetxController {
  final IAuthRepository authRepo;
  final IItemRepository itemRepo;
  late final BackupService backupService;
  late final ExcelService excelService;

  SettingsController({required this.authRepo, required this.itemRepo});

  var isAppLocked = false.obs;
  var isFingerprintEnabled = false.obs;
  var expiryAlertDays = 30.obs;

  @override
  void onInit() {
    super.onInit();
    backupService = Get.put(BackupService());
    excelService = Get.put(ExcelService());
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

  // --------------- Excel ---------------

  Future<void> exportExcel() async {
    // جلب الأصناف أولاً
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      barrierDismissible: false,
    );
    final allItems = await itemRepo.getItems();
    Get.back();

    if (allItems.isEmpty) {
      Get.snackbar('تنبيه', 'لا توجد أصناف لتصديرها.',
          backgroundColor: AppColors.storeYellow, colorText: AppColors.textDark, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // حساب الأصناف قريبة الانتهاء
    final nearExpiry = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>().nearExpiryItems
        : <dynamic>[];

    // حوار اختيار نوع التقرير
    final choice = await Get.dialog<String>(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        title: const Center(
          child: Text('اختر نوع التصدير', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختر نوع الملف الذي ترغب في تصديره',
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              _ExportOptionWidget(
                icon: Icons.inventory_2_outlined,
                title: 'المخزون الشامل',
                subtitle: 'جميع الأصناف مع كل التفاصيل',
                color: AppColors.displayBlue,
                value: 'standard',
              ),
              const SizedBox(height: 10),
              _ExportOptionWidget(
                icon: Icons.warning_amber_rounded,
                title: 'قريبة الانتهاء',
                subtitle: 'الأصناف التي تحتاج متابعة',
                color: AppColors.stockRed,
                value: 'near_expiry',
              ),
              const SizedBox(height: 10),
              _ExportOptionWidget(
                icon: Icons.balance_outlined,
                title: 'تقرير التسوية الشامل',
                subtitle: 'الفروقات بين الفعلي والنظام لجميع الأصناف',
                color: AppColors.storeYellow,
                value: 'settlement',
              ),
              const SizedBox(height: 10),
              _ExportOptionWidget(
                icon: Icons.trending_down_rounded,
                title: 'عجز التسوية',
                subtitle: 'الأصناف التي بها نقص عن النظام',
                color: Colors.orange.shade800,
                value: 'settlement_deficit',
              ),
              const SizedBox(height: 10),
              _ExportOptionWidget(
                icon: Icons.trending_up_rounded,
                title: 'زيادة التسوية',
                subtitle: 'الأصناف التي بها زيادة عن النظام',
                color: AppColors.systemGreen,
                value: 'settlement_surplus',
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Get.back(),
              child: const Text('إلغاء', style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );

    if (choice == null) return;

    List<ItemModel> itemsToExport = allItems;
    if (choice == 'near_expiry') {
      itemsToExport = nearExpiry.cast<ItemModel>();
    } else if (choice == 'settlement_deficit') {
      itemsToExport = Get.isRegistered<HomeController>() ? Get.find<HomeController>().deficitItems : allItems;
    } else if (choice == 'settlement_surplus') {
      itemsToExport = Get.isRegistered<HomeController>() ? Get.find<HomeController>().surplusItems : allItems;
    }

    if (itemsToExport.isEmpty) {
      Get.snackbar('تنبيه', 'لا توجد أصناف في هذا التقرير.',
          backgroundColor: AppColors.storeYellow, colorText: AppColors.textDark, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final success = await excelService.exportToExcel(itemsToExport, reportType: choice);
    if (success) {
      Get.snackbar('تصدير Excel', 'تم تصدير التقرير بنجاح.',
          backgroundColor: AppColors.systemGreen, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> importExcel() async {
    // تأكيد قبل الاستيراد
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text('تأكيد الاستيراد', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        content: const Text(
          'سيتم دمج بيانات الملف مع المخزون الحالي.\nالأصناف الموجودة بنفس الاسم ستُحدَّث، والجديدة ستُضاف.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textGrey),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('استيراد', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final importedItems = await excelService.importFromExcel();

    if (importedItems == null) {
      Get.snackbar('إلغاء', 'لم يتم اختيار ملف.',
          backgroundColor: AppColors.storeYellow, colorText: AppColors.textDark, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (importedItems.isEmpty) {
      Get.snackbar('تنبيه', 'الملف لا يحتوي على بيانات صالحة.',
          backgroundColor: AppColors.storeYellow, colorText: AppColors.textDark, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    Get.dialog(
      const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      barrierDismissible: false,
    );

    await itemRepo.upsertItems(importedItems);
    Get.back();

    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().loadItems();
    }

    Get.snackbar('استيراد Excel', 'تم استيراد ${importedItems.length} صنف بنجاح ✅',
        backgroundColor: AppColors.systemGreen, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
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

// تم فصل هذا العنصر إلى كلاس مستقل (StatelessWidget) لتجاوز مشكلة (Cache) في Hot Reload 
// ولضمان تطبيق الكود الجديد فورياً واختفاء الخطوط الرسومية تماماً
class _ExportOptionWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String value;

  const _ExportOptionWidget({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          // الإطار هنا منفصل كلياً ولن يسبب تداخل Skia
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Material(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Get.back(result: value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, decoration: TextDecoration.none)),
                        const SizedBox(height: 2),
                        Text(subtitle, 
                            style: const TextStyle(fontSize: 11, color: AppColors.textGrey, decoration: TextDecoration.none)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_left_rounded, size: 24, color: color.withOpacity(0.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
