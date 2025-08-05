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
      await _googleSignIn.signOut();
      print("Berhasil logout dari Google.");
    } catch (e) {
      print("Terjadi kesalahan saat logout Google: $e");
    }
  }

  // Fungsi login menggunakan Google
  static Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      await logoutFromGoogle();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {'success': false, 'message': 'Proses login dengan Google dibatalkan.'};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        return {'success': false, 'message': 'Tidak dapat mengakses akun Google Anda. Silakan coba lagi.'};
      }

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
          'message': 'Tidak dapat terhubung ke server. Silakan coba beberapa saat lagi.',
        };
      }
    } catch (e) {
      // Jangan tampilkan error sistem ke user
      return {
        'success': false,
        'message': 'Terjadi gangguan saat login Google. Silakan coba beberapa saat lagi.',
      };
    }
  }

  // Fungsi untuk mengirim access token ke backend Laravel
  static Future<Map<String, dynamic>?> _sendTokenToBackend(
    String accessToken,
  ) async {
    try {
      final Uri url = Uri.parse(
        "$prodUrl/auth/google/login",
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
        print('Gagal mendapatkan respon dari server: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print("Terjadi kesalahan saat mengirim token ke backend: $e");
      return null;
    }
  }

  // Login menggunakan email & password
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final Uri url = Uri.parse("$prodUrl/auth/login");

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
        return {
          'success': false,
          'message': json['message'] ?? 'Email atau password salah. Silakan cek kembali.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server. Silakan coba beberapa saat lagi.',
      };
    }
  }

  // Endpoint logout pada backend
  static String logoutUrl = "$prodUrl/auth/logout";

  // Fungsi logout untuk menghapus data dan mengarahkan ke halaman login
  static Future<void> logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _clearDataAndNavigateToLogin(context);
        return;
      }

      final response = await http.post(
        Uri.parse(logoutUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _clearDataAndNavigateToLogin(context);
      } else {
        // Tampilkan pesan ramah ke user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal logout. Silakan coba beberapa saat lagi.'),
          ),
        );
      }
    } catch (e) {
      // Tampilkan pesan ramah ke user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat logout. Silakan coba beberapa saat lagi.'),
        ),
      );
    }
  }

  static Future<void> _clearDataAndNavigateToLogin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await Future.delayed(const Duration(milliseconds: 500));

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }
}
