import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/models/user_model.dart';
import 'package:pemilihan_ketua_kelas_informatika/providers/vote_provider.dart';
import 'package:pemilihan_ketua_kelas_informatika/services/auth_service.dart';
import 'package:pemilihan_ketua_kelas_informatika/services/voting_service.dart';
import 'package:pemilihan_ketua_kelas_informatika/services/local_storage.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/custom_button.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/custom_textfield.dart';
import 'package:pemilihan_ketua_kelas_informatika/widgets/error_dialog.dart';

class ManageVotersScreen extends StatefulWidget {
  const ManageVotersScreen({super.key});

  @override
  State<ManageVotersScreen> createState() => _ManageVotersScreenState();
}

class _ManageVotersScreenState extends State<ManageVotersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _searchController = TextEditingController();

  UserModel? _editingUser;
  String _filterStatus = 'semua'; // 'semua', 'sudah', 'belum'
  String _sortBy = 'nama'; // 'nama', 'nim', 'status'
  bool _isLoading = false;
  static const String _votersStorageKey = 'managed_voters';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadManagedVoters();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _nimController.clear();
    _emailController.clear();
    _phoneController.clear();
    _editingUser = null;
    setState(() {});
  }

  Future<void> _saveManagedVoters() async {
    try {
      final voters = AuthService.dummyUsers.values
          .where((u) => !u.isAdmin)
          .toList();
      final votersJson = voters.map((v) => v.toJson()).toList();
      await LocalStorage.setString(_votersStorageKey, jsonEncode(votersJson));
    } catch (e) {
      debugPrint('Error saving voters: $e');
    }
  }

  Future<void> _loadManagedVoters() async {
    try {
      final savedData = LocalStorage.getString(_votersStorageKey);
      if (savedData != null) {
        final List<dynamic> jsonList = jsonDecode(savedData);
        for (var json in jsonList) {
          final user = UserModel.fromJson(json);
          if (!AuthService.dummyUsers.containsKey(user.nim)) {
            AuthService.dummyUsers[user.nim] = user;
            if (!AuthService.dummyNIM.contains(user.nim)) {
              AuthService.dummyNIM.add(user.nim);
            }
          }
        }
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading voters: $e');
    }
  }

  List<UserModel> _getFilteredAndSortedVoters() {
    final voters = AuthService.dummyUsers.values
        .where((u) => !u.isAdmin)
        .toList();

    // Search filter
    List<UserModel> filtered = voters;
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = voters.where((u) => 
        u.name.toLowerCase().contains(searchTerm) ||
        u.nim.toLowerCase().contains(searchTerm) ||
        u.email.toLowerCase().contains(searchTerm)
      ).toList();
    }

    // Status filter
    if (_filterStatus == 'sudah') {
      filtered = filtered.where((u) => u.hasVoted).toList();
    } else if (_filterStatus == 'belum') {
      filtered = filtered.where((u) => !u.hasVoted).toList();
    }

    // Sorting
    switch (_sortBy) {
      case 'nama':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'nim':
        filtered.sort((a, b) => a.nim.compareTo(b.nim));
        break;
      case 'status':
        filtered.sort((a, b) => b.hasVoted ? 1 : -1);
        break;
    }

    return filtered;
  }

  void _editUser(UserModel user) {
    setState(() {
      _editingUser = user;
      _nameController.text = user.name;
      _nimController.text = user.nim;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber;
    });
  }

  void _deleteUser(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pemilih'),
        content: Text('Apakah Anda yakin ingin menghapus ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              AuthService.dummyUsers.remove(user.nim);
              AuthService.dummyNIM.remove(user.nim);
              await _saveManagedVoters();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pemilih berhasil dihapus')),
              );
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditVote(BuildContext context, UserModel user) async {
    final vote = await VotingService.getUserVote(user.id);
    if (vote == null) {
      ErrorDialog.show(
        context,
        title: 'Error',
        message: 'Vote tidak ditemukan untuk siswa ini.',
      );
      return;
    }

    final candidates = await VotingService.getCandidates();
    int selectedCandidateId = vote.candidateId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Vote Siswa'),
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
                  items: candidates
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
            onPressed: () async {
              Navigator.pop(context);
              try {
                await VotingService.updateVote(vote.id, selectedCandidateId);
                if (context.mounted) {
                  context.read<VoteProvider>().fetchVoteResults();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vote berhasil diperbarui')),
                );
                setState(() {});
              } catch (e) {
                ErrorDialog.show(
                  context,
                  title: 'Error',
                  message: e.toString(),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUserVote(BuildContext context, UserModel user) async {
    final vote = await VotingService.getUserVote(user.id);
    if (vote == null) {
      ErrorDialog.show(
        context,
        title: 'Error',
        message: 'Vote tidak ditemukan untuk siswa ini.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Vote Siswa'),
        content: Text('Apakah Anda yakin ingin menghapus vote ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await VotingService.deleteVote(vote.id);
                if (context.mounted) {
                  context.read<VoteProvider>().fetchVoteResults();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vote siswa berhasil dihapus')),
                );
                setState(() {});
              } catch (e) {
                ErrorDialog.show(
                  context,
                  title: 'Error',
                  message: e.toString(),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _resetVotingStatus(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Status Voting'),
        content: Text('Apakah Anda yakin ingin reset status voting ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await VotingService.resetUserVote(user.id);
                
                // Update status voting di dummyUsers
                final updatedUser = user.copyWith(hasVoted: false);
                AuthService.dummyUsers[user.nim] = updatedUser;
                await AuthService.setHasVoted(user.nim, false);
                await _saveManagedVoters();

                if (context.mounted) {
                  context.read<VoteProvider>().fetchVoteResults();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Status voting berhasil direset')),
                );
                setState(() {});
              } catch (e) {
                ErrorDialog.show(
                  context,
                  title: 'Error',
                  message: e.toString(),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _resetAllVotingData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Semua Data Voting'),
        content: const Text(
          'PERINGATAN: Tindakan ini akan menghapus semua data voting termasuk:\n\n'
          '• Semua suara yang telah masuk\n'
          '• Status voting semua pemilih\n'
          '• Data kandidat akan direset ke nilai awal\n\n'
          'Apakah Anda yakin ingin melanjutkan?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Reset semua data voting
                await VotingService.resetData();

                // Reset status voting semua user
                final voters = AuthService.dummyUsers.values.where((u) => !u.isAdmin).toList();
                for (var voter in voters) {
                  final updatedVoter = voter.copyWith(hasVoted: false);
                  AuthService.dummyUsers[voter.nim] = updatedVoter;
                  await AuthService.setHasVoted(voter.nim, false);
                }

                // Simpan ke storage
                await _saveManagedVoters();

                // Refresh vote results di provider
                if (context.mounted) {
                  context.read<VoteProvider>().fetchVoteResults();
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua data voting berhasil direset'),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() {});
              } catch (e) {
                Navigator.pop(context);
                ErrorDialog.show(
                  context,
                  title: 'Error',
                  message: 'Gagal mereset data voting: ${e.toString()}',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reset Semua'),
          ),
        ],
      ),
    );
  }

  void _saveUser(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final nim = _nimController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    try {
      setState(() => _isLoading = true);

      // Validasi NIM sudah ada (untuk pengguna baru)
      if (_editingUser == null && 
          AuthService.dummyUsers.containsKey(nim)) {
        ErrorDialog.show(
          context,
          title: 'Error',
          message: 'NIM "$nim" sudah terdaftar di sistem',
        );
        return;
      }

      if (_editingUser != null) {
        // Edit: remove old jika NIM berubah
        if (_editingUser!.nim != nim) {
          // Validasi NIM baru tidak sudah ada
          if (AuthService.dummyUsers.containsKey(nim)) {
            ErrorDialog.show(
              context,
              title: 'Error',
              message: 'NIM "$nim" sudah terdaftar di sistem',
            );
            return;
          }
          AuthService.dummyUsers.remove(_editingUser!.nim);
          AuthService.dummyNIM.remove(_editingUser!.nim);
        }
        final updatedUser = _editingUser!.copyWith(
          nim: nim,
          name: name,
          email: email,
          phoneNumber: phone,
        );
        AuthService.dummyUsers[nim] = updatedUser;
        if (!AuthService.dummyNIM.contains(nim)) {
          AuthService.dummyNIM.add(nim);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data pemilih berhasil diperbarui')),
        );
      } else {
        // Add new
        await AuthService.register(name, nim, email, phone, AuthService.defaultPassword);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemilih berhasil ditambahkan')),
        );
      }
      await _saveManagedVoters();
      _clearForm();
      setState(() {});
    } catch (e) {
      ErrorDialog.show(
        context,
        title: 'Error',
        message: e.toString(),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredVoters = _getFilteredAndSortedVoters();
    final totalVoters = AuthService.dummyUsers.values.where((u) => !u.isAdmin).length;
    final votedCount = AuthService.dummyUsers.values
        .where((u) => !u.isAdmin && u.hasVoted)
        .length;
    final notVotedCount = totalVoters - votedCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pemilih'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Statistics Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        totalVoters.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text('Total Pemilih', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        votedCount.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text('Sudah Vote', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        notVotedCount.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const Text('Belum Vote', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            // Reset All Voting Data Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reset Data Voting',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tombol ini akan menghapus semua data voting dan mereset status voting semua pemilih.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _resetAllVotingData(context),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Reset Semua Data Voting'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Data Recovery Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pemulihan Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Jika data kandidat hilang setelah reset, gunakan fitur ini untuk memulihkan.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/data-recovery'),
                      icon: const Icon(Icons.restore),
                      label: const Text('Buka Data Recovery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form Section
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingUser != null ? 'Edit Pemilih' : 'Tambah Pemilih Baru',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'NIM',
                      hintText: '2024230001',
                      controller: _nimController,
                      enabled: !_isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'NIM tidak boleh kosong';
                        }
                        if (_editingUser == null && AuthService.dummyUsers.containsKey(value)) {
                          return 'NIM sudah terdaftar';
                        }
                        if (_editingUser != null && _editingUser!.nim != value &&
                            AuthService.dummyUsers.containsKey(value)) {
                          return 'NIM sudah terdaftar';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Nama Lengkap',
                      hintText: 'Masukkan nama lengkap',
                      controller: _nameController,
                      enabled: !_isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Email',
                      hintText: 'email@informatika4a.ac.id',
                      controller: _emailController,
                      enabled: !_isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Nomor Telepon',
                      hintText: '081234567890',
                      controller: _phoneController,
                      enabled: !_isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nomor telepon tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            label: _isLoading 
                              ? 'Loading...' 
                              : (_editingUser != null ? 'Update' : 'Tambah'),
                            onPressed: _isLoading ? null : () => _saveUser(context),
                            backgroundColor: const Color(0xFF1A5F7A),
                          ),
                        ),
                        if (_editingUser != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _clearForm,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                              ),
                              child: const Text('Batal'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Search, Filter, Sort
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  // Search
                  CustomTextField(
                    label: 'Cari Pemilih',
                    hintText: 'Cari nama, NIM, atau email',
                    controller: _searchController,
                    prefixIcon: Icons.search,
                  ),
                  const SizedBox(height: 12),
                  // Filter dan Sort
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filterStatus,
                          decoration: InputDecoration(
                            labelText: 'Filter',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'semua', child: Text('Semua')),
                            DropdownMenuItem(value: 'sudah', child: Text('Sudah Vote')),
                            DropdownMenuItem(value: 'belum', child: Text('Belum Vote')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _filterStatus = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sortBy,
                          decoration: InputDecoration(
                            labelText: 'Urutkan',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'nama', child: Text('Nama')),
                            DropdownMenuItem(value: 'nim', child: Text('NIM')),
                            DropdownMenuItem(value: 'status', child: Text('Status')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _sortBy = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Voters List
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: filteredVoters.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _searchController.text.isEmpty 
                            ? 'Belum ada pemilih'
                            : 'Tidak ada pemilih yang sesuai',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredVoters.length,
                      itemBuilder: (context, index) {
                        final user = filteredVoters[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: user.hasVoted ? Colors.green : Colors.orange,
                              child: Text(
                                user.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(user.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('NIM: ${user.nim}'),
                                Text(
                                  'Status: ${user.hasVoted ? 'Sudah Vote' : 'Belum Vote'}',
                                  style: TextStyle(
                                    color: user.hasVoted ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (user.hasVoted) ...[
                                  IconButton(
                                    icon: const Icon(Icons.how_to_vote, color: Colors.blue),
                                    onPressed: () => _showEditVote(context, user),
                                    tooltip: 'Edit Vote',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                                    onPressed: () => _deleteUserVote(context, user),
                                    tooltip: 'Hapus Vote',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh, color: Colors.orange),
                                    onPressed: () => _resetVotingStatus(context, user),
                                    tooltip: 'Reset Vote',
                                  ),
                                ],
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editUser(user),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteUser(context, user),
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
