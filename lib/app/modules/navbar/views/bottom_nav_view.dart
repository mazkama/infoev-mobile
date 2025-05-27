// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infoev/app/modules/explore/view/JelajahPage.dart';
import 'package:infoev/app/modules/home/views/home_view.dart';
import 'package:infoev/app/modules/navbar/controllers/bottom_nav_controller.dart';
import 'package:infoev/app/modules/charger_station/views/ChargerStationPage.dart';
import 'package:infoev/app/modules/ev_comparison/views/EvComparePage.dart';
import 'package:infoev/app/modules/profil/views/ProfilePage.dart';
import 'package:infoev/app/styles/app_colors.dart'; // Import palet warna


// Static mapping for tab items (unselected)
const tabBarItem = {
  "Beranda": Icons.home_outlined,
  "Jelajah": Icons.explore_outlined,
  "Charge": Icons.bolt_outlined,
  "Bandingkan": Icons.compare_arrows_outlined,
  "Lainnya": Icons.more_horiz_rounded,
};

// Static mapping for tab items (selected)
const tabBarItemselect = {
  "Beranda": Icons.home_filled,
  "Jelajah": Icons.explore,
  "Charge": Icons.bolt_rounded,
  "Bandingkan": Icons.compare_arrows_rounded,
  "Lainnya": Icons.more_horiz_rounded,
};

class BottomNavView extends GetView<BottomNavController> {
  // Make sure controller is properly initialized
  @override
  final BottomNavController controller = Get.put(BottomNavController());

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: controller.selectedmenu.value,
          children: [
            HomePage(),
            JelajahPage(),
            ChargerStationPage(),
            EVComparisonPage(),
            ProfilePage(),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            bottom:
                bottomPadding == 0.0
                    ? 0
                    : bottomPadding > 30
                    ? 50
                    : bottomPadding <= 25
                    ? 10
                    : 0,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            height: 75,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  tabBarItem.length,
                  (index) => buildItemBotNav(index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildItemBotNav(int index) {
    return Obx(
      () => InkWell(
        onTap: () { 
          FocusManager.instance.primaryFocus?.unfocus(); 
          controller.changemenuselection(index);
        },
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          padding: EdgeInsets.only(
            top: controller.selectedmenu.value == index ? 0 : 5,
          ),
          child: Column(
            children: [
              Icon(
                controller.selectedmenu.value == index
                    ? tabBarItemselect.values.elementAt(index)
                    : tabBarItem.values.elementAt(index),
                size: 24,
                color:
                    controller.selectedmenu.value == index
                        ? AppColors.textColor
                        : Colors.grey,
              ),
              Text(
                controller.selectedmenu.value == index
                    ? tabBarItemselect.keys.elementAt(index)
                    : tabBarItem.keys.elementAt(index),
                style:
                    controller.selectedmenu.value == index
                        ? TextStyle(
                          fontSize: 15,
                          fontFamily: 'SemiBold',
                          color: AppColors.textColor,
                        )
                        : TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
