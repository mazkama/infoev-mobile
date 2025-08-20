import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infoev/app/modules/explore/controllers/MerekController.dart';
import 'package:infoev/app/modules/login/controllers/LoginController.dart';
import 'package:infoev/app/modules/maintenance/views/maintenance_view.dart';
import 'package:infoev/app/routes/app_pages.dart';
import 'package:infoev/app/services/ConfigService.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:infoev/core/local_db.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:infoev/app/services/NotificationService.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi AdMob
  await MobileAds.instance.initialize();
  // MobileAds.instance.updateRequestConfiguration(
  //   RequestConfiguration(testDeviceIds: ['824C2245EB3E0B52167C2FC577C61A29']),
  // );

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize ConfigService
  bool configSuccess = await ConfigService().initialize();
  
  // Log current config values
  ConfigService().debugConfig();
  
  // Debug main values
  debugPrint("Main initialization: maintenance mode = ${ConfigService().isInMaintenanceMode}");

  // Initialize other services only if config was successful
  if (configSuccess) {
    // Initialize Notification Service
    await NotificationService().init();

    // Subscribe to topics
    await NotificationService().subscribeToTopic('infoev_news');
    await NotificationService().subscribeToTopic('infoev_vehicle');

    // Get FCM token for device
    String? token = await NotificationService().getToken();
    debugPrint('FCM Token: $token');
  }

  await LocalDB.init();
  
  // Initialize ScreenUtil
  await ScreenUtil.ensureScreenSize();
  
  Get.lazyPut(() => MerekController(), fenix: true);
  Get.lazyPut(() => LoginController(), fenix: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 857),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: GetMaterialApp(
            debugShowCheckedModeBanner: false,
            darkTheme: ThemeData(
              colorScheme: AppColors.darkColorScheme,
              useMaterial3: true,
            ),
            theme: ThemeData(
              colorScheme: AppColors.lightColorScheme,
              useMaterial3: true,
              // Additional theme configurations
              scaffoldBackgroundColor: AppColors.backgroundColor,
              cardColor: AppColors.cardBackgroundColor,
              dividerColor: AppColors.dividerColor,
              // AppBar theme
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.surfaceColor,
                foregroundColor: AppColors.textColor,
                elevation: 0,
              ),
              // Button themes
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: AppColors.textOnPrimary,
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: AppColors.linkColor),
              ),
            ),
            // Cek maintenance mode dan tentukan route awal
            initialRoute: ConfigService().isInMaintenanceMode 
                ? '/maintenance' 
                : AppPages.INITIAL,
            getPages: [
              ...AppPages.routes,
              // Tambahkan route maintenance
              GetPage(
                name: '/maintenance',
                page: () => const MaintenanceView(),
              ),
            ],
          ),
        );
      },
    );
  }
}