import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('Email dan password tidak boleh kosong');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.loginWithEmailAndPassword(
        email: email,
        password: password,
      );
      // AuthGate akan secara otomatis mendeteksi perubahan status login
      // dan mengarahkan pengguna ke HomeScreen tanpa perlu pushReplacement manual.
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showSnackbar('Email tidak ditemukan');
      } else if (e.code == 'wrong-password') {
        _showSnackbar('Password salah');
      } else if (e.code == 'invalid-credential') {
        _showSnackbar('Email atau password salah');
      } else if (e.code == 'invalid-email') {
        _showSnackbar('Format email tidak valid');
      } else {
        _showSnackbar('Terjadi kesalahan: ${e.message}');
      }
    } catch (e) {
      _showSnackbar('Terjadi kesalahan saat login');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Login Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SAFEVISION',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Login Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'MASUK',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Silakan masuk ke akun Anda',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Email
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EMAIL', style: theme.textTheme.labelMedium),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'email@anda.com',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Password
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('KATA SANDI', style: theme.textTheme.labelMedium),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _login,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.login, size: 16),
                                  const SizedBox(width: 8),
                                  const Text('MASUK'),
                                ],
                              ),
                            ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          textStyle: theme.textTheme.labelMedium,
                        ),
                        child: const Text('DAFTAR AKUN BARU'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Login Info (Demo Credentials style)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border.all(color: theme.colorScheme.surface),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SELAMAT DATANG DI SAFEVISION', style: theme.textTheme.labelMedium?.copyWith(color: theme.primaryColor)),
                    const SizedBox(height: 8),
                    Text('Sistem pemantauan keamanan pintar Anda.', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
