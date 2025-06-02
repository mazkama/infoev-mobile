import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infoev/app/modules/explore/controllers/MerekController.dart';
import 'package:infoev/app/modules/login/controllers/LoginController.dart';
import 'package:infoev/app/routes/app_pages.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:infoev/core/local_db.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:infoev/app/services/NotificationService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Notification Service
  await NotificationService().init();

  // Subscribe to topics (customize these based on your needs)
  await NotificationService().subscribeToTopic('infoev_news');
  await NotificationService().subscribeToTopic('infoev_vehicle');

  // Get FCM token for device
  String? token = await NotificationService().getToken();
  print('FCM Token: $token'); // You can send this token to your backend

  await LocalDB.init();
  Get.lazyPut(() => MerekController(), fenix: true);
  Get.lazyPut(() => LoginController(), fenix: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Menutup keyboard jika area di luar TextField disentuh
        FocusScope.of(context).unfocus();
      },
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: AppColors.lightColorScheme,
          useMaterial3: true,
          // Additional theme configurations using AppColors
          scaffoldBackgroundColor: AppColors.backgroundColor,
          cardColor: AppColors.cardBackgroundColor,
          dividerColor: AppColors.dividerColor,
          // AppBar theme
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surfaceColor,
            foregroundColor: AppColors.textColor,
            elevation: 0,
          ),
          // ElevatedButton theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: AppColors.textOnPrimary,
            ),
          ),
          // TextButton theme
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.linkColor),
          ),
        ),
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
      ),
    );
  }
}
