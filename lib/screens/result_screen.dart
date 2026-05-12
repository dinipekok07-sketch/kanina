import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/config/routes.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/candidate_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/vote_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/vote_result_chart.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/loading_widget.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isPieChart = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoteProvider>().fetchVoteResults();
      context.read<CandidateProvider>().fetchCandidates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Voting'),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.pie_chart),
                      label: Text('Pie'),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.bar_chart),
                      label: Text('Bar'),
                    ),
                  ],
                  selected: {_isPieChart},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _isPieChart = newSelection.first;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer2<VoteProvider, CandidateProvider>(
        builder: (context, voteProvider, candidateProvider, _) {
          if (voteProvider.isLoading || candidateProvider.isLoading) {
            return const LoadingWidget(message: 'Memuat hasil voting...');
          }

          final candidates = candidateProvider.candidates;
          final voteResults = <String, int>{};
          for (var candidate in candidates) {
            voteResults[candidate.getNames] =
                voteProvider.voteResults[candidate.id] ?? 0;
          }

          final hasVotes = voteResults.values.any((votes) => votes > 0);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasVotes)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Belum ada suara yang masuk. Berikut adalah daftar kandidat dan suara awal mereka.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),

                  // Chart
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: VoteResultChart(
                      candidates: candidates,
                      isPieChart: _isPieChart,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Statistics
                  Text(
                    'Statistik Voting',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _StatRow(
                          label: 'Total Kandidat',
                          value: candidates.length.toString(),
                        ),
                        const Divider(height: 16),
                        _StatRow(
                          label: 'Suara Masuk',
                          value: hasVotes ? 'Ya' : 'Belum',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Candidate Results
                  Text(
                    'Detail Kandidat',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      final candidate = candidates[index];
                      final votes = voteProvider.voteResults[candidate.id] ?? 0;

                      return FutureBuilder<double>(
                        future: voteProvider.getVotePercentage(candidate.id),
                        builder: (context, snapshot) {
                          final percentage = snapshot.data ?? 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              candidate.getNames,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Kandidat Nomor ${candidate.id}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '$votes suara',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF1A5F7A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${percentage.toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: percentage / 100,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF00B4D8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        },
        icon: const Icon(Icons.home),
        label: const Text('Kembali ke Dashboard'),
        backgroundColor: const Color(0xFF1A365D),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}