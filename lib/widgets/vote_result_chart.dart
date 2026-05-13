import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pemilihan_ketua_kelas_informatika/models/candidate_model.dart';

class VoteResultChart extends StatelessWidget {
  final List<CandidateModel> candidates;
  final bool isPieChart;

  const VoteResultChart({
    super.key,
    required this.candidates,
    this.isPieChart = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPieChart) {
      return _buildPieChart();
    } else {
      return _buildBarChart();
    }
  }

  Widget _buildPieChart() {
    final total = candidates.fold<int>(0, (sum, candidate) => sum + candidate.voteCount);
    if (total == 0) {
      return const Center(
        child: Text('Belum ada suara yang masuk'),
      );
    }

    final colors = [
      const Color(0xFF1A5F7A),
      const Color(0xFF00B4D8),
      const Color(0xFFFDCB6E),
      const Color(0xFF27AE60),
    ];

    return PieChart(
      PieChartData(
        sections: List.generate(
          candidates.length,
          (index) {
            final candidate = candidates[index];
            final percentage = (candidate.voteCount / total) * 100;
            return PieChartSectionData(
              value: candidate.voteCount.toDouble(),
              title: '${percentage.toStringAsFixed(1)}%',
              color: colors[index % colors.length],
              radius: 80,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            );
          },
        ),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildBarChart() {
    final maxVotes = candidates.isEmpty
        ? 1.0
        : candidates.map((c) => c.voteCount).reduce((a, b) => a > b ? a : b).toDouble();

    return BarChart(
      BarChartData(
        maxY: maxVotes,
        barGroups: List.generate(
          candidates.length,
          (index) {
            final candidate = candidates[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: candidate.voteCount.toDouble(),
                  color: const Color(0xFF00B4D8),
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          },
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= candidates.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    candidates[value.toInt()].getNames,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

