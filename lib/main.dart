import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'routes/app_pages.dart';

import 'data/interfaces/auth_repository_interface.dart';
import 'data/interfaces/item_repository_interface.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/sqlite_item_repository.dart';
import 'data/repositories/web_item_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // منع تدوير الشاشة - القفل على الوضع العمودي
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();
  
  Get.put<IAuthRepository>(AuthRepository(prefs), permanent: true);
  
  if (kIsWeb) {
    Get.put<IItemRepository>(WebItemRepository(), permanent: true);
  } else {
    Get.put<IItemRepository>(SqliteItemRepository(), permanent: true);
  }

  final authRepo = Get.find<IAuthRepository>();
  final isLocked = await authRepo.isAppLocked();
  final initialRoute = isLocked ? AppRoutes.LOGIN : AppRoutes.HOME;

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'مخزوني - StockFlow',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      getPages: AppPages.pages,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // إجبار التطبيق على الاتجاه العربي
          child: child!,
        );
      },
    );
  }
}
