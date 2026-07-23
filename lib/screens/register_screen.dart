import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackbar('Semua field tidak boleh kosong');
      return;
    }

    if (password.length < 6) {
      _showSnackbar('Password minimal 6 karakter');
      return;
    }

    if (password != confirmPassword) {
      _showSnackbar('Password dan konfirmasi password harus sama');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
      
      if (mounted) {
        _showSnackbar('Akun berhasil dibuat');
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showSnackbar('Email sudah digunakan');
      } else if (e.code == 'invalid-email') {
        _showSnackbar('Format email tidak valid');
      } else if (e.code == 'weak-password') {
        _showSnackbar('Password terlalu pendek');
      } else {
        _showSnackbar('Terjadi kesalahan: ${e.message}');
      }
    } catch (e) {
      if (e.toString().contains('auth-success-firestore-failed')) {
        _showSnackbar('Akun berhasil dibuat, tetapi profil gagal disimpan');
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _showSnackbar('Terjadi kesalahan saat registrasi');
      }
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'DAFTAR AKUN BARU',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Silakan isi data diri Anda',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NAMA LENGKAP', style: theme.textTheme.labelMedium),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Nama Lengkap',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
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
                      const SizedBox(height: 16),
                      
                      // Confirm Password
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('KONFIRMASI KATA SANDI', style: theme.textTheme.labelMedium),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
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
                              onPressed: _register,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.person_add, size: 16),
                                  const SizedBox(width: 8),
                                  const Text('DAFTAR'),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
