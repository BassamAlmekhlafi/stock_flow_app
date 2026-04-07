import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../core/constants/app_colors.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Decorative Header
            _buildHeader(),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('الأمان والخصوصية'),
                  const SizedBox(height: 12),
                  _buildSettingsGroup([
                    Obx(
                      () => _buildSettingsTile(
                        title: 'قفل التطبيق',
                        subtitle: 'طلب كلمة المرور عند الفتح',
                        icon: Icons.lock_outline_rounded,
                        iconColor: AppColors.displayBlue,
                        trailing: Switch.adaptive(
                          value: controller.isAppLocked.value,
                          onChanged: controller.toggleAppLock,
                          activeColor: AppColors.displayBlue,
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 50),
                    Obx(
                      () => _buildSettingsTile(
                        title: 'بصمة الإصبع',
                        subtitle: 'استخدام البصمة للدخول السريع',
                        icon: Icons.fingerprint_rounded,
                        iconColor: AppColors.systemGreen,
                        trailing: Switch.adaptive(
                          value: controller.isFingerprintEnabled.value,
                          onChanged: controller.toggleFingerprint,
                          activeColor: AppColors.systemGreen,
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 32),
                  _buildSectionTitle('تفضيلات النظام'),
                  const SizedBox(height: 12),
                  _buildSettingsGroup([
                    Obx(
                      () => _buildSettingsTile(
                        title: 'تنبيه قرب الانتهاء',
                        subtitle: 'تحديد متى يعتبر الصنف قريباً من الانتهاء',
                        icon: Icons.event_available_rounded,
                        iconColor: AppColors.storeYellow,
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: controller.expiryAlertDays.value,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.primary,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                            items: const [
                              DropdownMenuItem(value: 7, child: Text('7 أيام')),
                              DropdownMenuItem(
                                value: 14,
                                child: Text('14 يوم'),
                              ),
                              DropdownMenuItem(
                                value: 30,
                                child: Text('شهر واحد'),
                              ),
                              DropdownMenuItem(value: 60, child: Text('شهران')),
                              DropdownMenuItem(
                                value: 90,
                                child: Text('3 أشهر'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                controller.updateExpiryAlertDays(value);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 32),
                  _buildSectionTitle('النسخ الاحتياطي'),
                  const SizedBox(height: 12),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      title: 'أخذ نسخة احتياطية',
                      subtitle: 'حفظ بيانات المخزون في ملف آمن',
                      icon: Icons.cloud_download_rounded,
                      iconColor: AppColors.displayBlue,
                      onTap: controller.createBackup,
                    ),
                    const Divider(height: 1, indent: 50),
                    _buildSettingsTile(
                      title: 'استعادة نسخة احتياطية',
                      subtitle: 'استرجاع البيانات من ملف محفوظ مسبقاً',
                      icon: Icons.cloud_upload_rounded,
                      iconColor: AppColors.systemGreen,
                      onTap: controller.restoreBackup,
                    ),
                  ]),
                  
                   const SizedBox(height: 32),
                  _buildSectionTitle('استيراد وتصدير Excel'),
                  const SizedBox(height: 12),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      title: 'تصدير إلى Excel',
                      subtitle: 'حفظ جميع الأصناف كملف Excel (.xlsx)',
                      icon: Icons.upload_file_rounded,
                      iconColor: const Color(0xFF1B7E49),
                      onTap: controller.exportExcel,
                    ),
                    const Divider(height: 1, indent: 50),
                    _buildSettingsTile(
                      title: 'استيراد من Excel',
                      subtitle: 'دمج بيانات ملف Excel مع المخزون الحالي',
                      icon: Icons.download_for_offline_rounded,
                      iconColor: const Color(0xFF1565C0),
                      onTap: controller.importExcel,
                    ),
                  ]),

                  const SizedBox(height: 32),
                  _buildSectionTitle('حول التطبيق'),
                  const SizedBox(height: 12),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      title: 'نسخة التطبيق',
                      subtitle: '1.0.0 (Build 2026)',
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.textGrey,
                    ),
                    const Divider(height: 1, indent: 50),
                    _buildSettingsTile(
                      title: 'المطور',
                      subtitle: 'تم التطوير بواسطة المهندس/ بسام',
                      icon: Icons.code_rounded,
                      iconColor: AppColors.primary,
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Center(
              child: Text(
                'مخزوني - النسخة الاحترافية',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تخصيص التطبيق',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'قم بضبط إعدادات الأمان والتفضيلات الخاصة بك',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppColors.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
      ),
      trailing: trailing,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
