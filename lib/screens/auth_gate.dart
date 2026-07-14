import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder mendengarkan perubahan status autentikasi Firebase
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Jika stream masih memuat (loading)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Jika terdapat data user, berarti pengguna sudah login
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen(); // Langsung ke Home Screen
        }

        // Jika user null (belum login atau setelah logout)
        return const LoginScreen(); // Tampilkan halaman Login
      },
    );
  }
}
