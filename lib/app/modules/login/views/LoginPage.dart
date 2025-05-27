import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infoev/app/modules/home/views/home_view.dart';
import 'package:infoev/app/modules/login/controllers/LoginController.dart';
import 'package:infoev/app/modules/navbar/views/bottom_nav_view.dart';
import 'package:infoev/app/modules/register/views/RegisterPage.dart';
import 'package:infoev/app/styles/app_colors.dart'; // Import palet warna

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final controller = Get.find<LoginController>();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor, // Latar belakang putih
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Container(
            width: size.width < 500 ? double.infinity : 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackgroundColor, // Abu-abu terang
              borderRadius: BorderRadius.circular(16), // Sudut membulat
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight, // Bayangan halus
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    "Selamat Datang",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColor, // Hitam
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Silakan masuk untuk melanjutkan",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textSecondary, // Abu-abu gelap
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email Field
                  TextFormField(
                    controller: controller.emailController,
                    style: TextStyle(color: AppColors.textColor, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: AppColors.primaryColor,
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
                        borderSide: BorderSide(color: AppColors.primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? "Email is required"
                                : null,
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  Obx(
                    () => TextFormField(
                      controller: controller.passwordController,
                      obscureText: controller.obscurePassword.value,
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: AppColors.primaryColor, // Oranye untuk aksen
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscurePassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.primaryColor,
                          ),
                          onPressed: controller.togglePasswordVisibility,
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
                          borderSide: BorderSide(color: AppColors.primaryColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? "Password is required"
                                  : null,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login Button
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            controller.login();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor, // Ungu tua
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child:
                            controller.isLoading.value
                                ? CircularProgressIndicator(
                                  color:
                                      AppColors
                                          .accentColor, // Oranye untuk loading
                                )
                                : Text(
                                  'Login',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        AppColors
                                            .backgroundColor, // Putih untuk kontras
                                  ),
                                ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Teks atau sebagai pemisah
                  Center(
                    child: Text(
                      'atau',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Lanjutkan tanpa login dengan desain outline
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Arahkan ke halaman yang diinginkan tanpa login
                        Get.offAll(
                          () => BottomNavView(),
                          transition: Transition.downToUp,
                          duration: const Duration(milliseconds: 500),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.accentColor,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.accentColor,
                        textStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Lanjutkan tanpa login'),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Login with Google Button
                  SizedBox(
                    width: double.infinity,
                    child: Obx(
                      () => ElevatedButton.icon(
                        onPressed:
                            controller.isGoogleLoading.value
                                ? null
                                : () => controller.loginWithGoogle(),
                        icon:
                            controller.isGoogleLoading.value
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
                          controller.isGoogleLoading.value
                              ? 'Signing in...'
                              : 'Masuk dengan google',
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
                            side: BorderSide(color: AppColors.secondaryColor),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Register Text
                  Center(
                    child: GestureDetector(
                      onTap:
                          () => Get.offAll(
                            () => RegisterPage(),
                            transition: Transition.upToDown,
                            duration: const Duration(milliseconds: 400),
                          ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Belum mempunyai akun? ",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                            TextSpan(
                              text: "Daftar",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    AppColors.accentColor, // Oranye untuk aksen
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
