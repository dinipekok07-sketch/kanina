import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/config/routes.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/auth_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/services/auth_service.dart';
import 'package:pemilihan_ketua_kelas_informatika/utils/validators.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/custom_button.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/custom_textfield.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/error_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nimController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthProvider>().login(
            _nimController.text,
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Listen to auth state changes
          if (authProvider.isLoggedIn && !authProvider.isLoading) {
            Future.microtask(() {
              final route = authProvider.currentUser?.isAdmin == true
                  ? AppRoutes.adminDashboard
                  : AppRoutes.home;
              Navigator.of(context).pushReplacementNamed(route);
            });
          }

          if (authProvider.errorMessage != null &&
              authProvider.errorMessage!.isNotEmpty) {
            Future.microtask(() {
              ErrorDialog.show(
                context,
                title: 'Login Gagal',
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
                  Color(0xFF1A365D),
                  Color(0xFF3182CE),
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
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Center(
                        child: Image.asset(
                          'assets/images/app_logo.png', // Path file logo yang benar
                          width: 150,
                          height: 150,
                          fit: BoxFit.contain,
                          // Fallback icon jika file tidak ditemukan
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.how_to_vote,
                              size: 100,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          'Pemilihan Ketua Kelas\nInformatika 4A',
                          textAlign: TextAlign.center,
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
                          'Silakan login dengan NIM Anda',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
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
                                label: 'NIM',
                                hintText: '2024230001',
                                controller: _nimController,
                                prefixIcon: Icons.person,
                                keyboardType: TextInputType.text,
                                validator: Validators.validateNIM,
                              ),
                              const SizedBox(height: 20),
                              CustomTextField(
                                label: 'Password',
                                hintText: 'Masukkan password',
                                controller: _passwordController,
                                prefixIcon: Icons.lock,
                                obscureText: true,
                                validator: Validators.validatePassword,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                    activeColor: const Color(0xFF1A5F7A),
                                  ),
                                  const Expanded(
                                    child: Text(
                                      'Ingat saya',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              CustomButton(
                                label: 'Login',
                                onPressed: () => _handleLogin(context),
                                isLoading: authProvider.isLoading,
                                backgroundColor: const Color(0xFF1A5F7A),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'Data login valid:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Siswa: 2024230001 - 2024230040\nPassword: ${AuthService.defaultPassword}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Admin: ${AuthService.adminUsername}\nPassword: ${AuthService.adminPassword}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
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

