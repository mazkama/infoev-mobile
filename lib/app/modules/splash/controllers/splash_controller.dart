import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infoev/core/local_db.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    initialiazed();
    super.onInit();
  }

  void initialiazed() async {
    WidgetsFlutterBinding.ensureInitialized();  

    await Future.delayed(Duration(milliseconds: 1850));
    // if (!isLoggedIn) {
    //   Get.offAllNamed(Routes.LOGIN);
    // } else {
    //   Get.offAllNamed(Routes.NAVBAR);
    // }
    Get.offAllNamed(Routes.NAVBAR);
  }
}
