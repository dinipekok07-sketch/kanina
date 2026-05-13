import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/config/routes.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/auth_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/candidate_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/models/candidate_model.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/vote_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/candidate_card.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/custom_button.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/error_dialog.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/loading_widget.dart';

class CandidateListScreen extends StatefulWidget {
  const CandidateListScreen({super.key});

  @override
  State<CandidateListScreen> createState() => _CandidateListScreenState();
}

class _CandidateListScreenState extends State<CandidateListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null &&
          authProvider.currentUser!.isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin tidak dapat mengakses halaman kandidat.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
        return;
      }
      if (authProvider.currentUser != null &&
          authProvider.currentUser!.hasVoted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda sudah melakukan voting sebelumnya'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
        return;
      }
      context.read<CandidateProvider>().fetchCandidates();
    });
  }

  Future<void> _submitVote(BuildContext context) async {
    final candidateProvider = context.read<CandidateProvider>();
    final authProvider = context.read<AuthProvider>();
    final voteProvider = context.read<VoteProvider>();

    if (candidateProvider.selectedCandidate == null) {
      ErrorDialog.show(
        context,
        title: 'Pilihan Belum Dipilih',
        message: 'Silakan pilih satu kandidat terlebih dahulu.',
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
        if (!mounted) return;
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
                  Navigator.pushReplacementNamed(context, AppRoutes.result);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A365D),
                ),
                child: const Text('Lihat Hasil'),
              ),
            ],
          ),
        );
      } else {
        if (!mounted) return;
        ErrorDialog.show(
          context,
          title: 'Vote Gagal',
          message: voteProvider.errorMessage ??
              'Terjadi kesalahan saat mengirim suara.',
        );
      }
    }
  }

  void _showCandidateDetail(BuildContext context, CandidateModel candidate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Pasangan Nomor ${candidate.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                candidate.getNames,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Visi', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(candidate.visi),
              const SizedBox(height: 12),
              const Text('Misi', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(candidate.misi),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Kandidat'),
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
                        isSelected: candidateProvider.selectedCandidate?.id ==
                            candidate.id,
                        onVote: () {
                          candidateProvider.selectCandidate(candidate);
                        },
                        onDetail: () => _showCandidateDetail(context, candidate),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Consumer2<CandidateProvider, VoteProvider>(
                  builder: (context, candidateProvider, voteProvider, _) {
                    final selectedCandidate =
                        candidateProvider.selectedCandidate;
                    return CustomButton(
                      label: selectedCandidate == null
                          ? 'Pilih kandidat untuk voting'
                          : 'Vote ${selectedCandidate.getNames}',
                      onPressed: selectedCandidate == null
                          ? null
                          : () => _submitVote(context),
                      isLoading: voteProvider.isLoading,
                      backgroundColor: const Color(0xFF1A5F7A),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

