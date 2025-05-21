import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infoev/app/modules/explore/controllers/MerekController.dart';
import 'package:infoev/app/routes/app_pages.dart';
import 'package:infoev/core/local_db.dart';

void main() async {
  Get.lazyPut(() => MerekController());
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDB.init();
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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
          useMaterial3: true,
        ),
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
      ),
    );
  }
}
