import 'package:flutter/material.dart';
import 'package:pemilihan_ketua_kelas_informatika/services/local_storage.dart';
import 'dart:convert';

class DataRecoveryScreen extends StatefulWidget {
  const DataRecoveryScreen({super.key});

  @override
  State<DataRecoveryScreen> createState() => _DataRecoveryScreenState();
}

class _DataRecoveryScreenState extends State<DataRecoveryScreen> {
  String _storageData = 'Loading...';
  List<dynamic> _candidatesData = [];
  List<dynamic> _votesData = [];

  @override
  void initState() {
    super.initState();
    _loadStorageData();
  }

  Future<void> _loadStorageData() async {
    try {
      // Get all keys
      final keys = LocalStorage.getKeys();
      final data = <String, dynamic>{};

      for (final key in keys) {
        final value = LocalStorage.getString(key);
        if (value != null) {
          data[key] = value;
        }
      }

      // Parse candidates data
      final candidatesJson = LocalStorage.getString('candidates');
      if (candidatesJson != null) {
        _candidatesData = jsonDecode(candidatesJson);
      }

      // Parse votes data
      final votesJson = LocalStorage.getString('votes');
      if (votesJson != null) {
        _votesData = jsonDecode(votesJson);
      }

      setState(() {
        _storageData = data.toString();
      });
    } catch (e) {
      setState(() {
        _storageData = 'Error: $e';
      });
    }
  }

  Future<void> _restoreCandidates() async {
    if (_candidatesData.isNotEmpty) {
      await LocalStorage.setString('candidates', jsonEncode(_candidatesData));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data kandidat berhasil direstore')),
      );
      _loadStorageData(); // Refresh data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Recovery'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data di SharedPreferences:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_storageData),
            const SizedBox(height: 20),

            const Text(
              'Data Kandidat yang Tersimpan:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('${_candidatesData.length} kandidat'),
            for (final candidate in _candidatesData)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '${candidate['name1']} & ${candidate['name2']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),

            const SizedBox(height: 20),
            if (_candidatesData.isNotEmpty)
              ElevatedButton(
                onPressed: _restoreCandidates,
                child: const Text('Restore Data Kandidat'),
              ),

            const SizedBox(height: 20),
            const Text(
              'Data Votes yang Tersimpan:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('${_votesData.length} votes'),
          ],
        ),
      ),
    );
  }
}