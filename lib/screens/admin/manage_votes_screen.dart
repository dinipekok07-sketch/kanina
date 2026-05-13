import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/models/candidate_model.dart';
import 'package:pemilihan_ketua_kelas_informatika/models/vote_model.dart';
import 'package:pemilihan_ketua_kelas_informatika/services/auth_service.dart';
import 'package:pemilihan_ketua_kelas_informatika/services/voting_service.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/vote_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/error_dialog.dart';

class ManageVotesScreen extends StatefulWidget {
  const ManageVotesScreen({super.key});

  @override
  State<ManageVotesScreen> createState() => _ManageVotesScreenState();
}

class _ManageVotesScreenState extends State<ManageVotesScreen> {
  bool _isLoading = true;
  String? _error;
  List<VoteModel> _votes = [];
  List<CandidateModel> _candidates = [];
  List<VoteModel> _filteredVotes = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterVotes);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _votes = await VotingService.getVotes();
      _candidates = await VotingService.getCandidates();
      _filterVotes();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterVotes() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredVotes = List<VoteModel>.from(_votes);
    } else {
      _filteredVotes = _votes.where((vote) {
        final user = AuthService.getUserById(vote.userId);
        final candidate = _candidates.firstWhere(
          (candidate) => candidate.id == vote.candidateId,
          orElse: () => CandidateModel(
            id: vote.candidateId,
            name1: '-',
            name2: '-',
            visi: '',
            misi: '',
            voteCount: 0,
          ),
        );
        final userName = user?.name.toLowerCase() ?? '';
        final nim = user?.nim.toLowerCase() ?? vote.userId.toLowerCase();
        final candidateName = '${candidate.name1} ${candidate.name2}'.toLowerCase();
        return nim.contains(query) ||
            userName.contains(query) ||
            candidateName.contains(query);
      }).toList();
    }
    setState(() {});
  }

  Future<void> _deleteVote(String voteId) async {
    final provider = context.read<VoteProvider>();
    try {
      await provider.deleteVote(voteId);
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vote berhasil dihapus.')), 
      );
    } catch (e) {
      ErrorDialog.show(context, title: 'Error', message: e.toString());
    }
  }

  Future<void> _resetVote(String userId) async {
    final provider = context.read<VoteProvider>();
    try {
      await provider.resetVote(userId);
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status voting siswa berhasil direset.')),
      );
    } catch (e) {
      ErrorDialog.show(context, title: 'Error', message: e.toString());
    }
  }

  Future<void> _updateVote(String voteId, int candidateId) async {
    final provider = context.read<VoteProvider>();
    try {
      await provider.updateVote(voteId, candidateId);
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vote berhasil diupdate.')),
      );
    } catch (e) {
      ErrorDialog.show(context, title: 'Error', message: e.toString());
    }
  }

  void _showEditVoteDialog(VoteModel vote) {
    final candidateOptions = _candidates;
    int selectedCandidateId = vote.candidateId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Vote'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Pilih kandidat baru untuk vote ini:'),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedCandidateId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: candidateOptions
                      .map(
                        (candidate) => DropdownMenuItem<int>(
                          value: candidate.id,
                          child: Text(candidate.getNames),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedCandidateId = value;
                      });
                    }
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateVote(vote.id, selectedCandidateId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showConfirmDelete(VoteModel vote) {
    final user = AuthService.dummyUsers[vote.userId];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Vote'),
        content: Text(
          'Anda akan menghapus vote dari ${user?.name ?? vote.userId} (${vote.userId}).\n\nIni akan mengurangi suara kandidat dan mengizinkan siswa memilih lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteVote(vote.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showConfirmReset(VoteModel vote) {
    final user = AuthService.dummyUsers[vote.userId];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Vote'),
        content: Text(
          'Reset vote akan menghapus vote dari ${user?.name ?? vote.userId} (${vote.userId}) dan mengizinkan siswa memilih lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetVote(vote.userId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Voting Siswa'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari NIM, nama atau kandidat...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text('Terjadi kesalahan: $_error'),
                ),
              )
            else if (_filteredVotes.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _votes.isEmpty
                        ? 'Belum ada vote yang tercatat.'
                        : 'Tidak ada hasil pencarian.',
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredVotes.length,
                  itemBuilder: (context, index) {
                    final vote = _filteredVotes[index];
                    final user = AuthService.getUserById(vote.userId);
                    final candidate = _candidates.firstWhere(
                      (candidate) => candidate.id == vote.candidateId,
                      orElse: () => CandidateModel(
                        id: vote.candidateId,
                        name1: '-',
                        name2: '-',
                        visi: '',
                        misi: '',
                        voteCount: 0,
                      ),
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
                                        user?.name ?? vote.userId,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        vote.userId,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Sudah Vote',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Kandidat: ${candidate.getNames}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Waktu vote: ${vote.votedAt.toLocal()}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _showEditVoteDialog(vote),
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Edit'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _showConfirmReset(vote),
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Reset'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _showConfirmDelete(vote),
                                  icon: const Icon(Icons.delete, size: 18),
                                  label: const Text('Hapus'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
