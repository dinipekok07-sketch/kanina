import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/config/routes.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/auth_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/candidate_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/vote_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/candidate_card.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/custom_button.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/error_dialog.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/loading_widget.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({Key? key}) : super(key: key);

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      final voteProvider = context.read<VoteProvider>();
      if (authProvider.currentUser != null &&
          authProvider.currentUser!.isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin tidak dapat mengakses halaman voting.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
        return;
      }

      // Check if user has voted using vote provider
      if (authProvider.currentUser != null) {
        await voteProvider.checkUserVoted(authProvider.currentUser!.id);
        if (voteProvider.hasVoted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda sudah melakukan voting sebelumnya'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
          return;
        }
      }

      context.read<CandidateProvider>().fetchCandidates();
    });
  }

  void _submitVote(BuildContext context) async {
    final candidateProvider = context.read<CandidateProvider>();
    final authProvider = context.read<AuthProvider>();
    final voteProvider = context.read<VoteProvider>();

    if (authProvider.currentUser?.isAdmin == true) {
      ErrorDialog.show(
        context,
        title: 'Akses Ditolak',
        message: 'Admin tidak dapat melakukan voting.',
      );
      return;
    }

    if (voteProvider.hasVoted) {
      ErrorDialog.show(
        context,
        title: 'Voting Sudah Dilakukan',
        message: 'Anda sudah melakukan voting sebelumnya.',
      );
      return;
    }

    if (candidateProvider.selectedCandidate == null) {
      ErrorDialog.show(
        context,
        title: 'Pilihan Belum Dipilih',
        message: 'Silakan pilih satu kandidat terlebih dahulu',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Voting'),
        content: Text(
          'Apakah Anda yakin memilih ${candidateProvider.selectedCandidate!.getNames}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A365D),
            ),
            child: const Text('Yakin'),
          ),
        ],
      ),
    );

    if (confirmed == true && authProvider.currentUser != null) {
      final success = await voteProvider.submitVote(
        authProvider.currentUser!.id,
        candidateProvider.selectedCandidate!.id,
      );

      if (success) {
        await authProvider.setHasVoted(true);
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Vote Berhasil'),
              content: const Text('Terima kasih atas suara Anda!'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.result,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A365D),
                  ),
                  child: const Text('Lihat Hasil'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ErrorDialog.show(
            context,
            title: 'Vote Gagal',
            message: voteProvider.errorMessage ?? 'Terjadi kesalahan',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Kandidat'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<CandidateProvider>(
        builder: (context, candidateProvider, _) {
          if (candidateProvider.isLoading) {
            return const LoadingWidget(message: 'Memuat kandidat...');
          }

          if (candidateProvider.candidates.isEmpty) {
            return const Center(
              child: Text('Tidak ada kandidat tersedia'),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: candidateProvider.candidates.length,
                  itemBuilder: (context, index) {
                    final candidate = candidateProvider.candidates[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CandidateCard(
                        candidate: candidate,
                        isSelected:
                            candidateProvider.selectedCandidate?.id ==
                                candidate.id,
                        onVote: () {
                          candidateProvider.selectCandidate(candidate);
                        },
                      ),
                    );
                  },
                ),
              ),
              Consumer<VoteProvider>(
                builder: (context, voteProvider, _) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: CustomButton(
                      label: 'Submit Vote',
                      onPressed: () => _submitVote(context),
                      isLoading: voteProvider.isLoading,
                      backgroundColor: const Color(0xFF1A5F7A),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

