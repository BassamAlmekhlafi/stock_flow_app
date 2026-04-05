import 'package:get/get.dart';
import '../core/constants/app_routes.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../modules/home/views/home_view.dart';
import '../modules/home/controllers/home_controller.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/settings/controllers/settings_controller.dart';
import '../data/interfaces/auth_repository_interface.dart';
import '../data/interfaces/item_repository_interface.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController(authRepo: Get.find<IAuthRepository>()));
      }),
    ),
    GetPage(
      name: AppRoutes.HOME,
      page: () => const HomeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(() => HomeController(itemRepo: Get.find<IItemRepository>()));
      }),
    ),
    GetPage(
      name: AppRoutes.SETTINGS,
      page: () => const SettingsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SettingsController>(() => SettingsController(authRepo: Get.find<IAuthRepository>()));
      }),
    ),
  ];
}
