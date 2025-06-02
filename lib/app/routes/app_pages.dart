import 'package:get/get.dart';
import 'package:infoev/app/modules/calculator/views/CalculatorPage.dart';
import 'package:infoev/app/modules/charger_station/controllers/ChargerStationController.dart';
import 'package:infoev/app/modules/charger_station/views/ChargerStationPage.dart';
import 'package:infoev/app/modules/ev_comparison/controllers/EvCompareController.dart';
import 'package:infoev/app/modules/ev_comparison/views/EvComparePage.dart';
import 'package:infoev/app/modules/explore/controllers/MerekController.dart';
import 'package:infoev/app/modules/explore/view/JelajahPage.dart';
import 'package:infoev/app/modules/explore/view/SearchResultsPage.dart';
import 'package:infoev/app/modules/explore/view/TipeProduk.dart';
import 'package:infoev/app/modules/explore/view/VehicleDetail.dart';
import 'package:infoev/app/modules/home/views/home_view.dart';
import 'package:infoev/app/modules/login/views/LoginPage.dart';
import 'package:infoev/app/modules/login/controllers/LoginController.dart';
import 'package:infoev/app/modules/navbar/views/bottom_nav_view.dart';
import 'package:infoev/app/modules/news/views/news_all_view.dart';
import 'package:infoev/app/modules/profil/views/ProfilePage.dart';
import 'package:infoev/app/modules/register/controllers/RegisterController.dart';
import 'package:infoev/app/modules/register/views/RegisterPage.dart';
import 'package:infoev/app/modules/splash/controllers/splash_controller.dart';
import 'package:infoev/app/modules/news/controllers/news_controller.dart';
import 'package:infoev/app/modules/splash/views/splash_view.dart';
part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Path.SPLASH,
      page: () => SplashScreen(),
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
    ),
    GetPage(
      name: Path.LOGIN,
      page: () => LoginPage(),
      binding: BindingsBuilder(() {
        Get.put(LoginController());
      }),
    ),
    GetPage(
      name: Path.REGISTER,
      page: () => RegisterPage(),
      binding: BindingsBuilder(() {
        Get.put(RegisterController());
      }),
    ),
    GetPage(name: Path.NAVBAR, page: () => BottomNavView()),
    GetPage(
      name: Path.HOME,
      page: () => HomePage(),
      transition: Transition.rightToLeft,
      binding: BindingsBuilder(() {
        Get.put(NewsController());
      }),
    ),
    GetPage(
      name: Path.JELAJAH,
      page: () => JelajahPage(),
      transition: Transition.rightToLeft,
      binding: BindingsBuilder(() {
        Get.put(MerekController());
      }),
    ),
    GetPage(
      name: Path.SEARCH_RESULTS,
      page: () => const SearchResultsPage(),
      transition: Transition.rightToLeft,
      binding: BindingsBuilder(() {
        Get.put(MerekController());
      }),
    ),
    GetPage(
      name: Path.BRAND,
      page: () => const TipeProdukPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Path.VEHICLE,
      page: () => const VehicleDetailPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Path.NEWS,
      page: () => ArticalPage(),
      transition: Transition.rightToLeft,
      binding: BindingsBuilder(() {
        Get.put(NewsController());
      }),
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Path.CHARGER_STATION,
      page: () => ChargerStationPage(),
      transition: Transition.rightToLeft,
      binding: BindingsBuilder(() {
        Get.put(ChargerStationController());
      }),
    ),
    GetPage(
      name: Path.EV_COMPARISON,
      page: () => EVComparisonPage(),
      transition: Transition.rightToLeft,
      binding: BindingsBuilder(() {
        Get.put(EVComparisonController());
      }),
    ),
    GetPage(
      name: Path.PROFIL,
      transition: Transition.rightToLeft,
      page: () => ProfilePage(),
    ),
    GetPage(
      name: Path.CALCULATOR,
      page: () => const CalculatorPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // Tambahkan route lainnya jika ada
  ];
}
