import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infoev/app/modules/login/views/Logout.dart';
import 'package:get/get.dart';
import '../../../../core/local_db.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<Map<String, String?>> loadUserData() async {
    final token = LocalDB.getToken();
    if (token == null) return {'name': null, 'email': null};
    final name = LocalDB.getName();
    final email = LocalDB.getEmail();
    return {'name': name ?? 'User Noname', 'email': email ?? '-'};
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = LocalDB.getToken() != null;

    return Scaffold(
      backgroundColor: Colors.white,
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
                    FutureBuilder<Map<String, String?>>(
                      future: loadUserData(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildMenuItem(
                            icon: Icons.person,
                            title: 'Loading...',
                            subtitle: 'Loading...',
                            onTap: () {},
                            backgroundColor: Colors.grey.shade100,
                            iconColor: Colors.black,
                            textColor: Colors.black,
                            showArrow: false,
                          );
                        } else if (snapshot.hasError || !snapshot.hasData) {
                          return _buildMenuItem(
                            icon: Icons.person,
                            title: 'User Noname',
                            subtitle: '-',
                            onTap: () {},
                            backgroundColor: Colors.grey.shade100,
                            iconColor: Colors.black,
                            textColor: Colors.black,
                            showArrow: false,
                          );
                        } else {
                          final userData = snapshot.data!;
                          return _buildMenuItem(
                            icon: Icons.person,
                            title: userData['name'] ?? 'User Noname',
                            subtitle: userData['email'] ?? '-',
                            onTap: () {},
                            backgroundColor: Colors.grey.shade100,
                            iconColor: Colors.black,
                            textColor: Colors.black,
                            showArrow: false,
                          );
                        }
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(
                          0.15,
                        ), // background sedikit lebih terang
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(
                            0.4,
                          ), // border lebih tegas
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Info',
                                style: GoogleFonts.poppins(
                                  color: Colors.orange.shade700,
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
                              color: Colors.orange.shade900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Tampilkan fitur lain hanya jika sudah login
                  if (isLoggedIn) ...[
                    _buildMenuItem(
                      icon: Icons.calculate_outlined,
                      title: 'Kalkulator Kendaraan',
                      subtitle: 'Aplikasi kalkulator kendaraan listrik',
                      onTap: () {
                        Get.toNamed('/calculator');
                      },
                      backgroundColor: Colors.grey.shade100,
                      iconColor: Colors.black,
                      textColor: Colors.black,
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      icon: Icons.security,
                      title: 'Privasi & Keamanan',
                      subtitle: 'Hubungi kami, privacy policy',
                      onTap: () {
                        Get.toNamed('/privasi-keamanan');
                      },
                      backgroundColor: Colors.grey.shade100,
                      iconColor: Colors.black,
                      textColor: Colors.black,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Tombol logout jika login, login jika belum
                  _buildMenuItem(
                    icon:
                        isLoggedIn ? Icons.logout_rounded : Icons.login_rounded,
                    title: isLoggedIn ? 'Log Out' : 'Log In',
                    subtitle:
                        isLoggedIn
                            ? 'Keluar dari Aplikasi Infoev'
                            : 'Masuk untuk akses fitur lengkap aplikasi',
                    onTap: () {
                      if (isLoggedIn) {
                        Get.dialog(
                          AlertDialog(
                            title: Text(
                              'Konfirmasi Logout',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            content: Text(
                              'Apakah Anda yakin ingin keluar dari aplikasi?',
                              style: GoogleFonts.poppins(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(), // Close dialog
                                child: Text(
                                  'Batal',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Get.back(); // Close dialog
                                  Get.offAll(
                                    () => LogoutPage(),
                                  ); // Proceed with logout
                                },
                                child: Text(
                                  'Ya, Logout',
                                  style: GoogleFonts.poppins(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        Get.toNamed('/login');
                      }
                    },
                    backgroundColor:
                        isLoggedIn
                            ? Colors.red.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                    iconColor: isLoggedIn ? Colors.red : Colors.blue,
                    textColor:
                        isLoggedIn ? Colors.red.shade700 : Colors.blue.shade700,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color backgroundColor = Colors.white,
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
                      color: Colors.grey.shade600,
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
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }
}
