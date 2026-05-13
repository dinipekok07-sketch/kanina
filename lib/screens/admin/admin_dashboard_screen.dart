import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/config/routes.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/auth_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/candidate_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/vote_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/services/persistent_storage_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      body: Consumer3<AuthProvider, CandidateProvider, VoteProvider>(
        builder: (context, authProvider, candidateProvider, voteProvider, _) {
          final user = authProvider.currentUser;
          if (user == null || !user.isAdmin) {
            return const Center(
              child: Text('Akses ditolak. Hanya admin yang bisa masuk.'),
            );
          }

          final candidates = candidateProvider.candidates;
          final totalVotes = voteProvider.totalVotes;
          final voters = authProvider.dummyUsers.values.where((u) => !u.isAdmin).toList();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A365D), Color(0xFF3182CE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat datang, ${user.name}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Panel administrasi sistem voting Kelas Informatika 4A',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.manageVoters),
                                icon: const Icon(Icons.school, size: 20),
                                label: const Text('Kelola Mahasiswa'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.manageVotes),
                                icon: const Icon(Icons.how_to_vote, size: 20),
                                label: const Text('Kelola Voting'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Menu Grid
                  const Text(
                    'Menu Admin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _AdminMenuCard(
                        icon: Icons.people,
                        title: 'Kelola Kandidat',
                        subtitle: 'Tambah, edit, hapus kandidat',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.manageCandidates),
                      ),
                      _AdminMenuCard(
                        icon: Icons.school,
                        title: 'Kelola Pemilih',
                        subtitle: 'Kelola data mahasiswa',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.manageVoters),
                      ),
                      _AdminMenuCard(
                        icon: Icons.how_to_vote,
                        title: 'Kelola Siswa Memilih',
                        subtitle: 'Edit/hapus siswa yang telah voting',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.manageVotingStudents),
                      ),
                      _AdminMenuCard(
                        icon: Icons.how_to_reg,
                        title: 'Kelola Voting',
                        subtitle: 'Edit/reset/hapus vote siswa',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.manageVotes),
                      ),
                      _AdminMenuCard(
                        icon: Icons.schedule,
                        title: 'Kelola Jadwal',
                        subtitle: 'Atur waktu voting',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.manageSchedule),
                      ),
                      _AdminMenuCard(
                        icon: Icons.assessment,
                        title: 'Laporan',
                        subtitle: 'Rekap dan export data',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Storage Status
                  const Text(
                    'Status Penyimpanan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<Map<String, dynamic>>(
                    future: PersistentStorageService.getStorageInfo(),
                    builder: (context, snapshot) {
                      final storageInfo = snapshot.data ?? {};
                      final hasMainStorage = storageInfo['hasMainStorage'] ?? false;
                      final hasBackup = storageInfo['hasBackup'] ?? false;
                      final mainSize = storageInfo['mainSize'] ?? 0;
                      
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: hasMainStorage ? Colors.green[50] : Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasMainStorage ? Colors.green[200]! : Colors.orange[200]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  hasMainStorage ? Icons.storage : Icons.warning,
                                  color: hasMainStorage ? Colors.green[700] : Colors.orange[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  hasMainStorage ? 'Data Tersimpan Permanen' : 'Penyimpanan Belum Diinisialisasi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: hasMainStorage ? Colors.green[700] : Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              hasMainStorage 
                                ? 'Semua perubahan data kandidat tersimpan secara permanen. Data akan tetap ada meskipun aplikasi di-restart atau browser di-refresh.'
                                : 'Data kandidat belum tersimpan permanen. Pastikan admin telah menyimpan perubahan kandidat.',
                              style: TextStyle(
                                fontSize: 14,
                                color: hasMainStorage ? Colors.green[600] : Colors.orange[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: hasMainStorage ? Colors.green[100] : Colors.orange[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: hasMainStorage ? Colors.green[300]! : Colors.orange[300]!,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        hasMainStorage ? Icons.check_circle : Icons.warning,
                                        size: 16,
                                        color: hasMainStorage ? Colors.green[700] : Colors.orange[700],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        hasMainStorage ? 'Tersimpan' : 'Belum Tersimpan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: hasMainStorage ? Colors.green[700] : Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasMainStorage) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.blue[300]!),
                                    ),
                                    child: Text(
                                      '${(mainSize / 1024).toStringAsFixed(1)} KB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ),
                                ],
                                if (hasBackup) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.purple[100],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.purple[300]!),
                                    ),
                                    child: Text(
                                      'Backup ✓',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Text(
                    'Statistik Cepat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(label: 'Total Kandidat', value: candidates.length.toString()),
                        _StatItem(label: 'Total Pemilih', value: voters.length.toString()),
                        _StatItem(label: 'Total Suara', value: totalVotes.toString()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF1A5F7A)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A365D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
