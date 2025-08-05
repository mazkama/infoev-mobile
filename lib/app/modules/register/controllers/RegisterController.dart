import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:infoev/app/modules/login/model/UserModel.dart';
import 'package:infoev/core/halper.dart';
import 'package:infoev/app/services/AppException.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../routes/app_pages.dart';

class RegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final confirmPassC = TextEditingController();

  var isLoading = false.obs;
  var obscurePassword = true.obs;
  var obscureConfirmPassword = true.obs;

  Future<void> registerUser() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse('$prodUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nameC.text.trim(),
          'email': emailC.text.trim(),
          'password': passC.text.trim(),
          'password_confirmation': confirmPassC.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final user = UserModel(
          name: nameC.text.trim(),
          email: emailC.text.trim(),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(user.toJson()));

        ErrorHandlerService.showSuccess("Hi ${user.name}!");
        Get.offAllNamed(Routes.NAVBAR);
      } else {
        String message = data['message'] ?? 'Register failed';

        // Jika ada error validasi dari backend
        if (data['errors'] != null && data['errors'] is Map<String, dynamic>) {
          message = (data['errors'] as Map<String, dynamic>).entries
              .map((e) => '${e.key}: ${e.value[0]}')
              .join('\n');
          ErrorHandlerService.handleError(
            AppException(
              message: message,
              type: ErrorType.validation,
              statusCode: response.statusCode,
            ),
            showToUser: true,
          );
        } else {
          ErrorHandlerService.handleError(
            AppException(
              message: message,
              type: ErrorType.server,
              statusCode: response.statusCode,
            ),
            showToUser: true,
          );
        }
      }
    } catch (e) {
      ErrorHandlerService.handleError(
        e,
        showToUser: true,
      );
    }

    isLoading.value = false;
  }
}
