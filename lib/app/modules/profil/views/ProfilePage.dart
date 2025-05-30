import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infoev/app/modules/login/views/Logout.dart';
import 'package:get/get.dart';
import 'package:infoev/app/modules/profil/controllers/profile_controller.dart';
import 'package:infoev/app/styles/app_colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileController profileController = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isLoggedIn = profileController.isLoggedIn.value;
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Lainnya',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    if (isLoggedIn)
                      _buildMenuItem(
                        icon: Icons.person,
                        title: profileController.name.value,
                        subtitle: profileController.email.value,
                        onTap: () {},
                        backgroundColor: AppColors.backgroundSecondary,
                        iconColor: Colors.black,
                        textColor: Colors.black,
                        showArrow: false,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.secondaryColor.withOpacity(0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: AppColors.secondaryColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Info',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.secondaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Anda belum login. Silakan login untuk mengakses fitur lebih lengkap.',
                              style: GoogleFonts.poppins(
                                color: AppColors.errorColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (isLoggedIn) ...[
                      _buildMenuItem(
                        icon: Icons.calculate_outlined,
                        title: 'Kalkulator Kendaraan',
                        subtitle: 'Aplikasi kalkulator kendaraan listrik',
                        onTap: () {
                          Get.toNamed('/calculator');
                        },
                        backgroundColor: AppColors.backgroundSecondary,
                        iconColor: Colors.black,
                        textColor: Colors.black,
                      ),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        icon: Icons.security,
                        title: 'Privasi & Keamanan',
                        subtitle: 'Kelola kata sandi dan autentikasi',
                        onTap: () {},
                        backgroundColor: AppColors.backgroundSecondary,
                        iconColor: Colors.black,
                        textColor: Colors.black,
                      ),
                      const SizedBox(height: 24),
                    ],
                    _buildMenuItem(
                      icon: isLoggedIn ? Icons.logout_rounded : Icons.login_rounded,
                      title: isLoggedIn ? 'Log Out' : 'Log In',
                      subtitle: isLoggedIn
                          ? 'Keluar dari Aplikasi Infoev'
                          : 'Masuk untuk akses fitur lengkap aplikasi',
                      onTap: () {
                        if (isLoggedIn) {
                          Get.offAll(() => LogoutPage());
                        } else {
                          Get.toNamed('/login');
                        }
                      },
                      backgroundColor: isLoggedIn
                          ? AppColors.errorColor.withOpacity(0.1)
                          : AppColors.infoColor.withOpacity(0.1),
                      iconColor: isLoggedIn ? AppColors.errorColor : AppColors.infoColor,
                      textColor: isLoggedIn ? AppColors.errorColor : AppColors.infoColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color backgroundColor = AppColors.backgroundColor,
    Color iconColor = Colors.black,
    Color textColor = Colors.black, 
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
