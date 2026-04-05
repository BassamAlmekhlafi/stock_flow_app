import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';

class LoginView extends GetView<AuthController> {
  LoginView({super.key});

  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2_rounded, size: 100, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'مرحباً بك في مخزوني',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'الرجاء إدخال رمز المرور للمتابعة',
                style: TextStyle(fontSize: 16, color: AppColors.textGrey),
              ),
              const SizedBox(height: 50),
              Obx(() => TextField(
                controller: _passwordController,
                obscureText: !controller.isPasswordVisible.value,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'كلمة المرور',
                  errorText: controller.passwordError.value.isEmpty ? null : controller.passwordError.value,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                ),
              )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    controller.loginWithPassword(_passwordController.text.trim());
                  },
                  child: const Text('دخول'),
                ),
              ),
              Obx(() => Visibility(
                visible: controller.isFingerprintEnabled.value,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: controller.authenticateWithFingerprint,
                      icon: const Icon(Icons.fingerprint, color: AppColors.primary, size: 30),
                      label: const Text('الدخول بالبصمة', style: TextStyle(color: AppColors.primary, fontSize: 16)),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
