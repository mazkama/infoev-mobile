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
  Future<String> loadUserName() async {
    final name = LocalDB.getName();
    return name ?? 'User Noname';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 18),
            Center(
              child: Text(
                'More',
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
                  // Gunakan FutureBuilder untuk menunggu nama pengguna
                  FutureBuilder<String>(
                    future: loadUserName(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Jika sedang menunggu, tampilkan 'Loading...'
                        return _buildMenuItem(
                          icon: Icons.person,
                          title: 'Loading...',
                          subtitle: 'Pengaturan Profil Pengguna',
                          onTap: () {},
                          backgroundColor: Colors.grey.shade100,
                          iconColor: Colors.black,
                          textColor: Colors.black,
                        );
                      } else if (snapshot.hasError) {
                        // Jika ada error, tampilkan pesan error
                        return _buildMenuItem(
                          icon: Icons.person,
                          title: 'Error loading name',
                          subtitle: 'Pengaturan Profil Pengguna',
                          onTap: () {},
                          backgroundColor: Colors.grey.shade100,
                          iconColor: Colors.black,
                          textColor: Colors.black,
                        );
                      } else if (snapshot.hasData) {
                        final name = snapshot.data ?? 'User Noname';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMenuItem(
                              icon: Icons.person,
                              title: name,
                              subtitle: 'Pengaturan Profil Pengguna',
                              onTap: () {},
                              backgroundColor: Colors.grey.shade100,
                              iconColor: Colors.black,
                              textColor: Colors.black,
                            ),
                            SizedBox(height: 12),
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
                            SizedBox(height: 12),
                            _buildMenuItem(
                              icon: Icons.security,
                              title: 'Privasi & Keamanan',
                              subtitle: 'Kelola kata sandi dan autentikasi',
                              onTap: () {
                                // Arahkan ke halaman pengaturan keamanan
                              },
                              backgroundColor: Colors.grey.shade100,
                              iconColor: Colors.black,
                              textColor: Colors.black,
                            ),
                          ],
                        );
                      } else {
                        return Container();
                      }
                    },
                  ),

                  const SizedBox(height: 24),
                  const SizedBox(height: 16),

                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Log Out',
                    subtitle: 'Keluar dari Aplikasi Infoev',
                    onTap: () => Get.offAll(() => LogoutPage()),
                    backgroundColor: Colors.red.withOpacity(0.1),
                    iconColor: Colors.red,
                    textColor: Colors.red.shade700,
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
