import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infoev/app/modules/login/model/UserModel.dart';
import 'package:infoev/app/services/AuthService.dart';
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
      Get.snackbar(
        "Error",
        "Email and password are required",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
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
    } catch (e) {
      Get.snackbar(
        "Error",
        "An unexpected error occurred: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
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
    } catch (e) {
      Get.snackbar(
        "Error",
        "Google sign-in failed: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isGoogleLoading.value = false;
    }
  }

  // Common method to handle authentication response
  void handleAuthResponse(Map<String, dynamic> response) {
    if (response['success']) {
      saveUserSession(response);

      // Get user info for welcome message
      final user = UserModel.fromJson(response['user']);

      Get.snackbar(
        "Success",
        "Hi ${user.name}!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate to home screen
      Get.offAllNamed(Routes.NAVBAR);
    } else {
      Get.snackbar(
        "Error",
        response['message'] ?? "Authentication failed",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
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
