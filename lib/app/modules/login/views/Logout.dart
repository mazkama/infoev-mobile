import 'package:flutter/material.dart'; 
import 'package:infoev/app/services/AuthService.dart'; // Impor AuthService

class LogoutPage extends StatelessWidget {
  const LogoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Langsung logout ketika widget dibangun
    AuthService.logout(context);

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Menunggu proses logout selesai
      ),
    );
  }
}
