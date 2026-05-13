import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/config/routes.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/auth_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/candidate_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/schedule_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/vote_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/utils/helpers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _deadline;
  late Timer _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scheduleProvider = context.read<ScheduleProvider>();
      final session = scheduleProvider.currentSession;
      if (session != null) {
        _deadline = session.endDate;
        _timeRemaining = _deadline.difference(DateTime.now());
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {
            _timeRemaining = _deadline.difference(DateTime.now());
          });
        });
      }
      _loadData();
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final candidateProvider = context.read<CandidateProvider>();
    final voteProvider = context.read<VoteProvider>();

    if (authProvider.currentUser != null) {
      voteProvider.checkUserVoted(authProvider.currentUser!.id);
    }
    candidateProvider.fetchCandidates();
    voteProvider.fetchVoteResults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;
          final isAdmin = user?.isAdmin ?? false;
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
                          '${AppHelpers.getGreeting()}, ${isAdmin ? 'Admin' : user?.name ?? 'Pengguna'}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Selamat datang di sistem voting Kelas Informatika 4A',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (isAdmin)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Mode Admin aktif. Admin tidak dapat memilih suara, hanya melihat hasil voting.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Batas waktu pemilihan',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                _timeRemaining.isNegative
                                    ? 'Waktu Habis'
                                    : '${_timeRemaining.inDays} hari ${_timeRemaining.inHours.remainder(24).toString().padLeft(2, '0')}:'
                                        '${_timeRemaining.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
                                        '${_timeRemaining.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Voting Status Card
                  Consumer<VoteProvider>(
                    builder: (context, voteProvider, _) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: voteProvider.hasVoted
                              ? const Color(0xFF27AE60)
                              : const Color(0xFFF6E05E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              voteProvider.hasVoted
                                  ? Icons.check_circle
                                  : Icons.info,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    voteProvider.hasVoted
                                        ? 'Anda sudah melakukan voting'
                                        : 'Belum melakukan voting',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    voteProvider.hasVoted
                                        ? 'Terima kasih atas partisipasi Anda'
                                        : 'Jangan lewatkan kesempatan Anda untuk memilih',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Quick Overview Card
                  Consumer2<VoteProvider, CandidateProvider>(
                    builder: (context, voteProvider, candidateProvider, _) {
                      final candidates = candidateProvider.candidates;
                      final candidateCount = candidates.length;
                      final topCandidate = candidates.isNotEmpty
                          ? candidates.reduce((current, next) =>
                              next.voteCount > current.voteCount
                                  ? next
                                  : current)
                          : null;

                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatisticItem(
                                  label: 'Total Suara',
                                  value: voteProvider.totalVotes.toString(),
                                ),
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: Colors.grey[300],
                                ),
                                _StatisticItem(
                                  label: 'Total Kandidat',
                                  value: candidateCount.toString(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hasil Sementara',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (topCandidate != null &&
                                    voteProvider.totalVotes > 0) ...[
                                  Text(
                                    '${topCandidate.getNames} memimpin dengan ${topCandidate.voteCount} suara',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: voteProvider.totalVotes == 0
                                        ? 0
                                        : topCandidate.voteCount /
                                            voteProvider.totalVotes,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: const AlwaysStoppedAnimation(
                                      Color(0xFF3182CE),
                                    ),
                                  ),
                                ] else ...[
                                  const Text(
                                    'Belum ada suara yang masuk. Data kandidat akan tampil segera setelah voting dimulai.',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Text(
                    'Menu Utama',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  if (isAdmin) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _MenuButton(
                            icon: Icons.admin_panel_settings,
                            label: 'Panel Admin',
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.adminDashboard);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _MenuButton(
                            icon: Icons.assessment,
                            label: 'Hasil Voting',
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.result);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MenuButton(
                            icon: Icons.school,
                            label: 'Kelola Mahasiswa',
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.manageVoters);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _MenuButton(
                            icon: Icons.how_to_vote,
                            label: 'Kelola Voting',
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.manageVotes);
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _MenuButton(
                            icon: Icons.people,
                            label: 'Kandidat',
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.candidateList,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _MenuButton(
                            icon: Icons.how_to_vote,
                            label: 'Vote Sekarang',
                            onPressed: () {
                              context
                                  .read<CandidateProvider>()
                                  .fetchCandidates()
                                  .then(
                                (_) {
                                  Navigator.pushNamed(context, AppRoutes.voting);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MenuButton(
                            icon: Icons.assessment,
                            label: 'Hasil Voting',
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.result);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _MenuButton(
                            icon: Icons.info,
                            label: 'Tentang',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Tentang Aplikasi'),
                                  content: const Text(
                                    'Aplikasi ini adalah sistem Pemilihan Ketua Kelas Informatika untuk siswa. ' 
                                    'Gunakan menu Kandidat untuk melihat calon, Vote Sekarang untuk memilih, dan Hasil Voting untuk melihat hasil sementara.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Tutup'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatisticItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatisticItem({
    required this.label,
    required this.value,
  });

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
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1A5F7A), size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

