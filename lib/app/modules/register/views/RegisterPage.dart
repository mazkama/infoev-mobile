import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infoev/app/modules/login/controllers/LoginController.dart';
import 'package:infoev/app/modules/register/controllers/RegisterController.dart';
import 'package:infoev/app/modules/login/views/LoginPage.dart';
import 'package:infoev/app/styles/app_colors.dart';

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final controller = Get.put(RegisterController());
  final controllerLogin = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Container(
            width: size.width < 500 ? double.infinity : 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: controller.formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Buat Akun Baru',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silakan daftar untuk melanjutkan',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name Field
                  TextFormField(
                    controller: controller.nameC,
                    style: TextStyle(
                      color: AppColors.textColor,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      labelStyle: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppColors.accentColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primaryColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.accentColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    controller: controller.emailC,
                    style: TextStyle(
                      color: AppColors.textColor,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: AppColors.accentColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.secondaryTextColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.secondaryTextColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.accentColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Wajib diisi';
                      if (!GetUtils.isEmail(val)) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  Obx(
                    () => TextFormField(
                      controller: controller.passC,
                      obscureText: controller.obscurePassword.value,
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          color: AppColors.secondaryTextColor,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: AppColors.accentColor,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscurePassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.accentColor,
                          ),
                          onPressed: () => controller.obscurePassword.toggle(),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.secondaryTextColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.secondaryTextColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.accentColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      validator: (val) => val == null || val.length < 6 ? 'Minimal 6 karakter' : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  Obx(
                    () => TextFormField(
                      controller: controller.confirmPassC,
                      obscureText: controller.obscureConfirmPassword.value,
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password',
                        labelStyle: TextStyle(
                          color: AppColors.secondaryTextColor,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: AppColors.accentColor,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscureConfirmPassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.accentColor,
                          ),
                          onPressed: () => controller.obscureConfirmPassword.toggle(),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.secondaryTextColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.secondaryTextColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.accentColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      validator: (val) => val != controller.passC.text ? 'Password tidak sama' : null,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Register Button
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () {
                                if (controller.formKey.currentState!.validate()) {
                                  controller.registerUser();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: controller.isLoading.value
                            ? CircularProgressIndicator(
                                color: AppColors.accentColor,
                              )
                            : Text(
                                'Daftar',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.backgroundColor,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Login with Google Button
                  SizedBox(
                    width: double.infinity,
                    child: Obx(
                      () => ElevatedButton.icon(
                        onPressed: controllerLogin.isGoogleLoading.value
                            ? null
                            : () => controllerLogin.loginWithGoogle(),
                        icon: controllerLogin.isGoogleLoading.value
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accentColor,
                                ),
                              )
                            : Image.asset(
                                'assets/images/icon_google.png',
                                height: 24,
                                width: 24,
                              ),
                        label: Text(
                          controllerLogin.isGoogleLoading.value
                              ? 'Signing in...'
                              : 'Daftar dengan google',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textColor,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cardBackgroundColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppColors.secondaryTextColor),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Back to Login
                  Center(
                    child: GestureDetector(
                      onTap: () => Get.offAll(
                        () => LoginPage(),
                        transition: Transition.downToUp,
                        duration: const Duration(milliseconds: 400),
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Sudah punya akun? ',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                            TextSpan(
                              text: 'Masuk',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
