import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:infoev/core/halper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:infoev/app/modules/login/views/LoginPage.dart';

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Fungsi logout dari Google
  static Future<void> logoutFromGoogle() async {
    try {
      await _googleSignIn.signOut(); // Logout dari Google SignIn
      print("Logged out from Google.");
    } catch (e) {
      print("Error during Google sign-out: $e");
    }
  }

  // Fungsi login menggunakan Google
  static Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      // Step 1: Logout dari Google jika ada sesi sebelumnya
      await logoutFromGoogle();

      // Step 2: Login melalui Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {'success': false, 'message': 'User canceled Google sign-in.'};
      }

      // Step 2: Ambil accessToken dari Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        return {'success': false, 'message': 'Access token is null.'};
      }

      print("Google Access Token: $accessToken");

      // Step 3: Kirim accessToken ke backend Laravel
      final response = await _sendTokenToBackend(accessToken);

      if (response != null) {
        return {
          'success': true,
          'token': response['token'],
          'user': response['user'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to authenticate with Laravel backend.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Fungsi untuk mengirim access token ke backend Laravel
  static Future<Map<String, dynamic>?> _sendTokenToBackend(
    String accessToken,
  ) async {
    try {
      final Uri url = Uri.parse(
        "$baseUrlDev/auth/google/login",
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': accessToken}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        return {
          'token': jsonResponse['data']['token'],
          'user': jsonResponse['data']['user'],
        };
      } else {
        print('Backend response failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print("Error sending token to backend: $e");
      return null;
    }
  }

  // Login menggunakan email & password
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final Uri url = Uri.parse("$baseUrlDev/api/auth/login");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['status'] == true) {
        return {
          'success': true,
          'token': json['data']['token'],
          'user': json['data']['user'],
        };
      } else {
        return {'success': false, 'message': json['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Endpoint logout pada backend
  static const String logoutUrl =
      "$baseUrlDev/auth/logout";

  // Fungsi logout untuk menghapus data dan mengarahkan ke halaman login
  static Future<void> logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(
        'token',
      ); // Mendapatkan token dari SharedPreferences

      if (token == null) {
        // Jika tidak ada token, langsung logout tanpa melakukan request ke backend
        _clearDataAndNavigateToLogin(context);
        return;
      }

      // Kirim request logout ke backend dengan token
      final response = await http.post(
        Uri.parse(logoutUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Menyertakan token dalam header
        },
      );

      // Periksa apakah request logout berhasil
      if (response.statusCode == 200) {
        // Jika berhasil, hapus data dan arahkan ke halaman login
        _clearDataAndNavigateToLogin(context);
      } else {
        // Jika request logout gagal, tampilkan pesan error
        print('Logout failed with status: ${response.statusCode}');
        // Optional: Tampilkan pesan kesalahan kepada pengguna
      }
    } catch (e) {
      print("Error during logout: $e");
      // Optional: Tampilkan pesan kesalahan kepada pengguna
    }
  }

  // Fungsi untuk menghapus data dan navigasi ke halaman login
  static Future<void> _clearDataAndNavigateToLogin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Tunggu sebentar agar UI bisa menyesuaikan sebelum navigasi
    await Future.delayed(const Duration(milliseconds: 500));

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false, // Menghapus semua halaman sebelumnya
    );
  }
}
