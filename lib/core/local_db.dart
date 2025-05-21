// ignore_for_file: unused_element, prefer_conditional_assignment

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// import '../app/modules/login/model/UserModel.dart';

class LocalDB {
  static SharedPreferences? _prefs;

  /// Inisialisasi SharedPreferences
  static Future<void> init() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  /// Pastikan `_prefs` sudah diinisialisasi sebelum digunakan
  static Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      throw Exception(
        "LocalDB belum diinisialisasi. Pastikan untuk memanggil `await LocalDB.init()` sebelum mengakses properti atau metode.",
      );
    }
  }

  // butuh data user login

  static String? getName() {
    final userData = _prefs?.getString('user');
    if (userData != null) {
      try {
        final user = jsonDecode(userData);

        // Validasi apakah name ada dan bukan string kosong
        if (user['name'] != null && user['name'].toString().trim().isNotEmpty) {
          return user['name'];
        } else {
          return 'User Noname';
        }
      } catch (e) {
        print("Gagal parsing data user: $e");
        return 'User Noname';
      }
    } else {
      // Jika tidak ada data user sama sekali
      return 'User Noname';
    }
  }

  static String? getToken() {
    return _prefs?.getString('token');
  }

  // --- Properti dan Metode ---

  // static void setFirstTime(bool isFirstTime) {
  //   _prefs?.setBool('isFirstTime', isFirstTime);
  // }

  // static bool get isFirstTime {
  //   return _prefs?.getBool('isFirstTime') ?? true;
  // }

  // static void setLoggedIn(bool value) {
  //   _prefs?.setBool('isLoggedIn', value);
  // }

  // static setToken(String token) {
  //   _prefs?.setString('token', token);
  // }

  // static String? getToken() {
  //   return _prefs?.getString('token');
  // }

  // static void setIdShipment(String id) {
  //   _prefs?.setString('idShipment', id);
  // }

  // static String? getIdShipment() {
  //   return _prefs?.getString('idShipment');
  // }

  // static void setisDone(String done) {
  //   _prefs?.setString('is_done', done);
  // }

  // static String? getisDone() {
  //   return _prefs?.getString('is_done');
  // }

  // static void removeToken() {
  //   _prefs?.remove('token');
  // }

  // static setemailSSO(String? emailSSO) {
  //   _prefs?.setString('emailSSO', emailSSO ?? '');
  // }

  // static String? get emailSSO {
  //   return _prefs?.getString('emailSSO');
  // }

  // static set credentials(Map<String, String>? creds) {
  //   if (creds != null) {
  //     final username = creds['username'] ?? '';
  //     final password = creds['password'] ?? '';
  //     final combined = '$username:$password';
  //     _prefs?.setString('credentials', combined);
  //   } else {
  //     _prefs?.remove('credentials');
  //   }
  // }

  // static Map<String, String>? get credentials {
  //   final creds = _prefs?.getString('credentials');
  //   if (creds != null && creds.contains(':')) {
  //     final parts = creds.split(':');
  //     if (parts.length == 2) {
  //       return {'username': parts[0], 'password': parts[1]};
  //     }
  //   }
  //   return null;
  // }

  // static void setService(bool isService) {
  //   _prefs?.setBool('isBackground', isService);
  // }

  // static bool get isService {
  //   return _prefs?.getBool('isBackground') ?? false;
  // }
}
