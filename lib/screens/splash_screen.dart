import 'package:flutter/material.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Menunda selama 3 detik sebelum berpindah ke halaman LoginScreen
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Menggunakan pushReplacement agar user diarahkan ke AuthGate
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthGate()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan Scaffold sebagai dasar halaman tanpa AppBar
    return Scaffold(
      // Tidak ada padding atau margin, menampilkan gambar fullscreen
      body: Image.asset(
        'assets/images/splash.png',
        width: double.infinity, // Gambar selebar layar
        height: double.infinity, // Gambar setinggi layar
        fit: BoxFit.cover, // Proporsi gambar menutupi seluruh ruang
      ),
    );
  }
}
