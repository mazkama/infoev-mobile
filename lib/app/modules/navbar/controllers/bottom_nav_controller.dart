// bottom_nav_controller.dart
import 'package:get/get.dart';
import 'package:infoev/app/modules/login/views/Logout.dart';

class BottomNavController extends GetxController {
  // Current selected tab index
  final RxInt selectedmenu = 0.obs;

  // Method to change the selected menu
  void changemenuselection(int index) {
    // If the logout button is clicked (assuming it's the last tab)
    if (index == 3) {
      // Handle logout logic here if needed
      // For example: AuthService.logout();
      // return;
      LogoutPage(key: null);
    }
    selectedmenu.value = index;
  }

  // // List of routes corresponding to each tab
  // final List<String> routes = [
  //   '/home',
  //   '/explore',
  //   '/charge',
  //   '/compare',
  // ];

  // // Change tab and navigate to corresponding route if using named routes
  // void navigateToTab(int index) {
  //   selectedmenu.value = index;
  //   Get.offAllNamed(routes[index]);
  // }
}