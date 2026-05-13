import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/config/routes.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/auth_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/theme_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/utils/helpers.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;
          if (user == null) {
            return const Center(
              child: Text('User tidak ditemukan'),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Avatar
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A365D), Color(0xFF3182CE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          AppHelpers.getInitials(user.name),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User Name
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.nim,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Profile Information Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _ProfileField(
                          label: 'NIM',
                          value: user.nim,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _ProfileField(
                          label: 'Peran',
                          value: user.isAdmin ? 'Admin' : 'Pemilih',
                          icon: Icons.admin_panel_settings,
                        ),
                        const SizedBox(height: 16),
                        _ProfileField(
                          label: 'Nama Lengkap',
                          value: user.name,
                          icon: Icons.badge,
                        ),
                        const SizedBox(height: 16),
                        _ProfileField(
                          label: 'Email',
                          value: user.email,
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 16),
                        _ProfileField(
                          label: 'Nomor Telepon',
                          value: user.phoneNumber,
                          icon: Icons.phone_outlined,
                        ),
                        const SizedBox(height: 16),
                        _ProfileField(
                          label: 'Status Voting',
                          value: user.hasVoted ? 'Sudah Melakukan' : 'Belum',
                          icon: Icons.how_to_vote,
                          valueColor: user.hasVoted
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Settings Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pengaturan',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dark Mode Toggle
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.dark_mode,
                                  color: Color(0xFF1A5F7A),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Mode Gelap',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            Switch(
                              value: themeProvider.isDarkMode,
                              onChanged: (value) {
                                themeProvider.setDarkMode(value);
                              },
                              activeColor: const Color(0xFF00B4D8),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  CustomButton(
                    label: 'Logout',
                    onPressed: () {
                      _showLogoutDialog(context);
                    },
                    backgroundColor: Colors.red[600],
                    isLoading: authProvider.isLoading,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.home);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Color(0xFF1A5F7A)),
                    ),
                    child: const Text('Kembali ke Beranda'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout().then((_) {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.login,
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _ProfileField({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1A5F7A), size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

