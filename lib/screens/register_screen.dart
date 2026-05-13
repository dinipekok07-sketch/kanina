import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/config/routes.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/auth_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/utils/validators.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/custom_button.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/custom_textfield.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/error_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister(BuildContext context) {
    if (!_agreeToTerms) {
      ErrorDialog.show(
        context,
        title: 'Setujui Syarat & Ketentuan',
        message:
            'Anda harus menyetujui syarat dan ketentuan untuk melanjutkan.',
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ErrorDialog.show(
          context,
          title: 'Password Tidak Cocok',
          message: 'Password dan konfirmasi password harus sama.',
        );
        return;
      }

      // Call register and handle the result
      context
          .read<AuthProvider>()
          .register(
            _nameController.text,
            _nimController.text,
            _emailController.text,
            _phoneController.text,
            _passwordController.text,
          )
          .then((success) {
        if (success && mounted) {
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Registrasi Berhasil'),
              content: const Text(
                'Akun Anda telah terdaftar. Silakan login dengan NIM dan password yang telah Anda buat.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.login,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5F7A),
                  ),
                  child: const Text('Ke Halaman Login'),
                ),
              ],
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Show error if registration failed
          if (authProvider.errorMessage != null &&
              authProvider.errorMessage!.isNotEmpty &&
              authProvider.isLoading == false) {
            Future.microtask(() {
              ErrorDialog.show(
                context,
                title: 'Registrasi Gagal',
                message: authProvider.errorMessage!,
              );
              authProvider.clearError();
            });
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A5F7A),
                  Color(0xFF00B4D8),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Center(
                        child: Icon(
                          Icons.person_add,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Daftar Akun Baru',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Buat akun untuk dapat memilih',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              CustomTextField(
                                label: 'Nama Lengkap',
                                hintText: 'Masukkan nama lengkap',
                                controller: _nameController,
                                prefixIcon: Icons.person,
                                validator: Validators.validateName,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                label: 'NIM',
                                hintText: '20241003',
                                controller: _nimController,
                                prefixIcon: Icons.badge,
                                keyboardType: TextInputType.number,
                                validator: Validators.validateNIM,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                label: 'Email',
                                hintText: 'nama@informatika.ac.id',
                                controller: _emailController,
                                prefixIcon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                validator: Validators.validateEmail,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                label: 'Nomor Telepon',
                                hintText: '081234567890',
                                controller: _phoneController,
                                prefixIcon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                validator: Validators.validatePhoneNumber,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                label: 'Password',
                                hintText: 'Buat password kuat',
                                controller: _passwordController,
                                prefixIcon: Icons.lock,
                                obscureText: true,
                                validator: Validators.validatePassword,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                label: 'Konfirmasi Password',
                                hintText: 'Ulangi password',
                                controller: _confirmPasswordController,
                                prefixIcon: Icons.lock_outline,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Konfirmasi password tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _agreeToTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _agreeToTerms = value ?? false;
                                      });
                                    },
                                    activeColor: const Color(0xFF1A5F7A),
                                  ),
                                  const Expanded(
                                    child: Text(
                                      'Saya setuju dengan syarat & ketentuan',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              CustomButton(
                                label: 'Daftar',
                                onPressed: () => _handleRegister(context),
                                isLoading: authProvider.isLoading,
                                backgroundColor: const Color(0xFF1A5F7A),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Sudah punya akun? ',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pushReplacementNamed(
                                      context,
                                      AppRoutes.login,
                                    ),
                                    child: const Text(
                                      'Login di sini',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A5F7A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

