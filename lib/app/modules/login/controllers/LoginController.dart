import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:infoev/app/modules/login/model/UserModel.dart';
import 'package:infoev/app/services/AuthService.dart';
import 'package:infoev/app/services/AppException.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../routes/app_pages.dart';

class LoginController extends GetxController {
  // Text controllers for form fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Observable states
  final isLoading = false.obs;
  final isGoogleLoading = false.obs;
  final obscurePassword = true.obs;

  // Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  // Handle regular email/password login
  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ErrorHandlerService.handleError(
        AppException(
          message: 'Email dan password wajib diisi.',
          type: ErrorType.validation,
        ),
        showToUser: true,
      );
      return;
    }

    isLoading.value = true;

    try {
      final response = await AuthService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      handleAuthResponse(response);
    } on PlatformException catch (_) {
      // Tangkap error platform khusus (misal network error)
      ErrorHandlerService.handleError(
        AppException(
          message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
          type: ErrorType.network,
        ),
        showToUser: true,
      );
    } catch (e) {
      ErrorHandlerService.handleError(
        AppException(
          message: 'Terjadi gangguan saat login. Silakan coba beberapa saat lagi.',
          type: ErrorType.unknown,
          originalError: e,
        ),
        showToUser: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Handle Google Sign-In
  Future<void> loginWithGoogle() async {
    isGoogleLoading.value = true;

    try {
      final response = await AuthService.loginWithGoogle();
      handleAuthResponse(response);
    } on PlatformException catch (_) {
      ErrorHandlerService.handleError(
        AppException(
          message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
          type: ErrorType.network,
        ),
        showToUser: true,
      );
    } catch (e) {
      ErrorHandlerService.handleError(
        AppException(
          message: 'Login Google gagal. Silakan coba beberapa saat lagi.',
          type: ErrorType.unknown,
          originalError: e,
        ),
        showToUser: true,
      );
    } finally {
      isGoogleLoading.value = false;
    }
  }

  // Common method to handle authentication response
  void handleAuthResponse(Map<String, dynamic> response) {
    if (response['success'] == true) {
      saveUserSession(response);

      final user = UserModel.fromJson(response['user']);
      ErrorHandlerService.showSuccess("Selamat datang, ${user.name}!");
      Get.offAllNamed(Routes.NAVBAR);
    } else {
      // Deteksi error network/server/validation
      final message = response['message']?.toString().toLowerCase() ?? '';
      ErrorType errorType = ErrorType.validation;

      if (message.contains('koneksi') || message.contains('network') || message.contains('socket')) {
        errorType = ErrorType.network;
      } else if (message.contains('server') || message.contains('internal')) {
        errorType = ErrorType.server;
      } else if (message.contains('token') || message.contains('expired')) {
        errorType = ErrorType.authentication;
      }

      ErrorHandlerService.handleError(
        AppException(
          message: '', // biarkan handler menampilkan pesan ramah sesuai tipe
          type: errorType,
        ),
        showToUser: true,
      );
    }
  }

  // Save user session data
  Future<void> saveUserSession(Map<String, dynamic> data) async {
    print('[DEBUG] Full login response data: $data');
    print('[DEBUG] data[token]: ${data['token']}');
    print('[DEBUG] Length: ${data['token'].toString().length}');

    final user = UserModel.fromJson(data['user']);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('token', data['token']);
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  // Check if user is already logged in (can be called from onInit)
  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Clear form fields
  void clearForm() {
    emailController.clear();
    passwordController.clear();
  }
}
