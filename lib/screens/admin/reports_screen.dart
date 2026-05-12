import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/candidate_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/vote_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/utils/helpers.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/schedule_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/services/auth_service.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/custom_button.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/vote_result_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CandidateProvider>().fetchCandidates();
      context.read<VoteProvider>().fetchVoteResults();
    });
  }

  void _exportToPDF(BuildContext context) async {
    final candidates = context.read<CandidateProvider>().candidates;
    final totalVotes = context.read<VoteProvider>().totalVotes;
    final voters = AuthService.dummyUsers.values.where((u) => !u.isAdmin).toList();
    final votedCount = voters.where((u) => u.hasVoted).length;
    final session = context.read<ScheduleProvider>().currentSession;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Laporan Hasil Voting', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              if (session != null) ...[
                pw.Text('Judul: ${session.title}'),
                pw.Text('Deskripsi: ${session.description}'),
                pw.Text('Periode: ${session.startDate} - ${session.endDate}'),
                pw.SizedBox(height: 10),
              ],
              pw.Text('Total Suara: $totalVotes'),
              pw.Text('Total Pemilih: ${voters.length}'),
              pw.Text('Sudah Vote: $votedCount'),
              pw.Text('Belum Vote: ${voters.length - votedCount}'),
              pw.SizedBox(height: 20),
              pw.Text('Hasil Voting:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['No', 'Nama Kandidat', 'Suara', 'Persentase'],
                data: List<List<String>>.generate(
                  candidates.length,
                  (index) {
                    final candidate = candidates[index];
                    final percentage = totalVotes > 0 ? (candidate.voteCount / totalVotes * 100).toStringAsFixed(1) : '0.0';
                    return [
                      (index + 1).toString(),
                      candidate.getNames,
                      candidate.voteCount.toString(),
                      '$percentage%',
                    ];
                  },
                ),
              ),
            ],
          );
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/laporan_voting.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: 'Laporan Hasil Voting');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF berhasil diexport')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error export PDF: $e')),
      );
    }
  }

  void _exportToExcel(BuildContext context) async {
    final candidates = context.read<CandidateProvider>().candidates;
    final totalVotes = context.read<VoteProvider>().totalVotes;
    final voters = AuthService.dummyUsers.values.where((u) => !u.isAdmin).toList();
    final votedCount = voters.where((u) => u.hasVoted).length;
    final session = context.read<ScheduleProvider>().currentSession;

    var workbook = excel.Excel.createExcel();
    excel.Sheet sheetObject = workbook['Hasil Voting'];

    // Header
    sheetObject.cell(excel.CellIndex.indexByString('A1')).value = excel.TextCellValue('Laporan Hasil Voting');
    sheetObject.cell(excel.CellIndex.indexByString('A3')).value = excel.TextCellValue('Judul');
    sheetObject.cell(excel.CellIndex.indexByString('B3')).value = excel.TextCellValue(session?.title ?? '');
    sheetObject.cell(excel.CellIndex.indexByString('A4')).value = excel.TextCellValue('Deskripsi');
    sheetObject.cell(excel.CellIndex.indexByString('B4')).value = excel.TextCellValue(session?.description ?? '');
    sheetObject.cell(excel.CellIndex.indexByString('A5')).value = excel.TextCellValue('Total Suara');
    sheetObject.cell(excel.CellIndex.indexByString('B5')).value = excel.IntCellValue(totalVotes);
    sheetObject.cell(excel.CellIndex.indexByString('A6')).value = excel.TextCellValue('Total Pemilih');
    sheetObject.cell(excel.CellIndex.indexByString('B6')).value = excel.IntCellValue(voters.length);
    sheetObject.cell(excel.CellIndex.indexByString('A7')).value = excel.TextCellValue('Sudah Vote');
    sheetObject.cell(excel.CellIndex.indexByString('B7')).value = excel.IntCellValue(votedCount);

    // Table headers
    sheetObject.cell(excel.CellIndex.indexByString('A9')).value = excel.TextCellValue('No');
    sheetObject.cell(excel.CellIndex.indexByString('B9')).value = excel.TextCellValue('Nama Kandidat');
    sheetObject.cell(excel.CellIndex.indexByString('C9')).value = excel.TextCellValue('Suara');
    sheetObject.cell(excel.CellIndex.indexByString('D9')).value = excel.TextCellValue('Persentase');

    // Data
    for (int i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      final percentage = totalVotes > 0 ? (candidate.voteCount / totalVotes * 100) : 0.0;
      sheetObject.cell(excel.CellIndex.indexByString('A${10 + i}')).value = excel.IntCellValue(i + 1);
      sheetObject.cell(excel.CellIndex.indexByString('B${10 + i}')).value = excel.TextCellValue(candidate.getNames);
      sheetObject.cell(excel.CellIndex.indexByString('C${10 + i}')).value = excel.IntCellValue(candidate.voteCount);
      sheetObject.cell(excel.CellIndex.indexByString('D${10 + i}')).value = excel.DoubleCellValue(percentage);
    }

    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/laporan_voting.xlsx');
      await file.writeAsBytes(workbook.encode()!);

      await Share.shareXFiles([XFile(file.path)], text: 'Laporan Hasil Voting');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel berhasil diexport')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error export Excel: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Rekap'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer3<CandidateProvider, VoteProvider, ScheduleProvider>(
        builder: (context, candidateProvider, voteProvider, scheduleProvider, _) {
          final candidates = candidateProvider.candidates;
          final totalVotes = voteProvider.totalVotes;
          final voters = AuthService.dummyUsers.values.where((u) => !u.isAdmin).toList();
          final votedCount = voters.where((u) => u.hasVoted).length;
          final session = scheduleProvider.currentSession;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Voting',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total Suara',
                        value: totalVotes.toString(),
                        icon: Icons.how_to_vote,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Sudah Vote',
                        value: '$votedCount/${voters.length}',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Belum Vote',
                        value: '${voters.length - votedCount}',
                        icon: Icons.pending,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Kandidat',
                        value: candidates.length.toString(),
                        icon: Icons.people,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Chart
                const Text(
                  'Hasil Voting',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 300,
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
                  child: VoteResultChart(candidates: candidates),
                ),
                const SizedBox(height: 24),

                // Detailed Results
                const Text(
                  'Detail Hasil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final candidate = candidates[index];
                    final percentage = totalVotes > 0 ? (candidate.voteCount / totalVotes * 100).toStringAsFixed(1) : '0.0';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              AppHelpers.imageProviderFromUrl(candidate.photoUrl1),
                          child: AppHelpers.imageProviderFromUrl(candidate.photoUrl1) == null
                              ? Text(candidate.id.toString())
                              : null,
                        ),
                        title: Text(candidate.getNames),
                        subtitle: Text('${candidate.voteCount} suara'),
                        trailing: Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Session Info
                if (session != null) ...[
                  const Text(
                    'Informasi Sesi',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Judul: ${session.title}'),
                        Text('Deskripsi: ${session.description}'),
                        Text('Mulai: ${session.startDate}'),
                        Text('Selesai: ${session.endDate}'),
                        Text('Status: ${session.isActive ? 'Aktif' : 'Tidak Aktif'}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Export Buttons
                const Text(
                  'Export Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: 'Export PDF',
                        onPressed: () => _exportToPDF(context),
                        backgroundColor: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        label: 'Export Excel',
                        onPressed: () => _exportToExcel(context),
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
