import 'package:get/get.dart';
import '../../../../core/local_db.dart';

class ProfileController extends GetxController {
  final RxString name = ''.obs;
  final RxString email = ''.obs;
  final RxBool isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  void loadUserData() {
    final token = LocalDB.getToken();
    isLoggedIn.value = token != null;
    if (isLoggedIn.value) {
      name.value = LocalDB.getName() ?? 'User Noname';
      email.value = LocalDB.getEmail() ?? '-';
    } else {
      name.value = 'User Noname';
      email.value = '-';
    }
  }
}
