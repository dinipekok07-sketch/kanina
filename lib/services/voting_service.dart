import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pemilihan_ketua_kelas_informatika/models/candidate_model.dart';
import 'package:pemilihan_ketua_kelas_informatika/models/vote_model.dart';
import 'package:pemilihan_ketua_kelas_informatika/services/auth_service.dart';
import 'package:pemilihan_ketua_kelas_informatika/utils/constants.dart';
import 'package:pemilihan_ketua_kelas_informatika/utils/exceptions.dart';
import 'local_storage.dart';
import 'persistent_storage_service.dart';

class VotingService {
  static const String _candidatesKey = 'candidates';
  static const String _votesKey = 'votes';
  static List<VoteModel> _votes = [];

  // Load votes from storage
  static Future<void> _loadVotes() async {
    final savedData = LocalStorage.getString(_votesKey);
    if (savedData != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(savedData);
        _votes = jsonList.map((json) => VoteModel.fromJson(json)).toList();
      } catch (e) {
        _votes = [];
      }
    }
  }

  // Save votes to storage
  static Future<void> _saveVotes() async {
    final jsonList = _votes.map((v) => v.toJson()).toList();
    await LocalStorage.setString(_votesKey, jsonEncode(jsonList));
  }

  // Default candidates data (fallback if no saved data)
  static final List<CandidateModel> _defaultCandidates = [
    CandidateModel(
      id: 1,
      name1: 'zaharani putri (2024230007)',
      name2: 'dini aprilianti (2024230014)',
      visi:
          'Membangun Kelas Informatika 4A yang Solid, Kreatif, dan Berprestasi',
      misi:
          '1. Mengadakan study club setiap minggu\n2. Membuat grup diskusi online yang aktif\n3. Mengkoordinir tugas kelompok dengan sistem yang adil\n4. Mengadakan acara kebersamaan kelas (class gathering)',
      photoUrl1: 'assets/images/kandidat1.jpg',
      photoUrl2: 'assets/images/kandidat2.jpg',
      voteCount: 0,
    ),
    CandidateModel(
      id: 2,
      name1: 'intan purnama sari (2024230012)',
      name2: 'Putri Amelia (2024230010)',
      visi:
          'Mewujudkan Kelas Informatika 4A yang Inovatif dan Berdaya Saing Global',
      misi:
          '1. Mengadakan workshop coding setiap bulan\n2. Membangun portofolio project kelas\n3. Mengikuti lomba-lomba kompetitif\n4. Membuka kelas sharing dengan alumni',
      photoUrl1: 'assets/images/kandidat3.jpg',
      photoUrl2: 'assets/images/kandidat4.jpg',
      voteCount: 0,
    ),
    CandidateModel(
      id: 3,
      name1: 'tri agustin (2024230016)',
      name2: 'verlin agustin (2024230019)',
      visi: 'Kelas Informatika 4A yang Harmonis dan Berbasis Teknologi',
      misi:
          '1. Membuat sistem informasi kelas berbasis web\n2. Mengadakan mentoring untuk mahasiswa yang kesulitan\n3. Menjalin komunikasi yang baik antara mahasiswa dan dosen\n4. Mengadakan bakti sosial sebagai bentuk kepedulian',
      photoUrl1: 'assets/images/kandidat5.jpg',
      photoUrl2: 'assets/images/kandidat6.jpg',
      voteCount: 0,
    ),
  ];

  // Get all candidates
  static Future<List<CandidateModel>> getCandidates() async {
    await Future.delayed(const Duration(milliseconds: 300));

    List<CandidateModel> candidates;

    try {
      // Try to load from PersistentStorageService first (more robust for large data)
      final savedCandidates = await PersistentStorageService.loadCandidates();
      if (savedCandidates != null && savedCandidates.isNotEmpty) {
        debugPrint('[VotingService] Loaded ${savedCandidates.length} candidates from PersistentStorage');
        candidates = savedCandidates;
        candidates = _migrateAssetCandidatePaths(candidates);
      } else {
        // Fallback to old LocalStorage format
        final savedData = LocalStorage.getString(_candidatesKey);
        if (savedData != null) {
          try {
            final List<dynamic> jsonList = jsonDecode(savedData);
            candidates =
                jsonList.map((json) => CandidateModel.fromJson(json)).toList();
            debugPrint('[VotingService] Loaded ${candidates.length} candidates from LocalStorage (old format)');
            
            // Migrate to PersistentStorage
            await _saveCandidates(candidates);
          } catch (e) {
            debugPrint('[VotingService] Error parsing old LocalStorage data: $e');
            // Initialize with default candidates and save them
            candidates = _defaultCandidates.map((c) => CandidateModel.fromJson(c.toJson())).toList();
            await _saveCandidates(candidates);
            debugPrint('[VotingService] Initialized with default candidates');
          }
        } else {
          // If no saved data, initialize with default candidates and save them
          debugPrint('[VotingService] No saved data found, initializing with defaults');
          candidates = _defaultCandidates.map((c) => CandidateModel.fromJson(c.toJson())).toList();
          await _saveCandidates(candidates);
          debugPrint('[VotingService] Default candidates saved to storage');
        }
      }
    } catch (e) {
      debugPrint('[VotingService] Error loading candidates: $e');
      // Initialize with default candidates and save them
      candidates = _defaultCandidates.map((c) => CandidateModel.fromJson(c.toJson())).toList();
      await _saveCandidates(candidates);
      debugPrint('[VotingService] Default candidates saved to storage after error');
    }

    // Sync vote counts with actual votes
    await _syncVoteCounts(candidates);

    return candidates;
  }

  static List<CandidateModel> _migrateAssetCandidatePaths(List<CandidateModel> candidates) {
    final updated = candidates.map((candidate) {
      if (candidate.id == 1) {
        final photo1 = candidate.photoUrl1?.startsWith('assets/') == true
            ? candidate.photoUrl1
            : 'assets/images/kandidat1.jpg';
        final photo2 = candidate.photoUrl2?.startsWith('assets/') == true
            ? candidate.photoUrl2
            : 'assets/images/kandidat2.jpg';
        return candidate.copyWith(photoUrl1: photo1, photoUrl2: photo2);
      }

      if (candidate.id == 2) {
        final photo1 = candidate.photoUrl1?.startsWith('assets/') == true
            ? candidate.photoUrl1
            : 'assets/images/kandidat1.jpg';
        final photo2 = candidate.photoUrl2?.startsWith('assets/') == true
            ? candidate.photoUrl2
            : 'assets/images/kandidat2.jpg';
        return candidate.copyWith(photoUrl1: photo1, photoUrl2: photo2);
      }

      if (candidate.id == 3) {
        final photo1 = candidate.photoUrl1?.startsWith('assets/') == true
            ? candidate.photoUrl1
            : 'assets/images/kandidat1.jpg';
        final photo2 = candidate.photoUrl2?.startsWith('assets/') == true
            ? candidate.photoUrl2
            : 'assets/images/kandidat2.jpg';
        return candidate.copyWith(photoUrl1: photo1, photoUrl2: photo2);
      }

      return candidate;
    }).toList();
    return updated;
  }

  // Sync candidate vote counts with actual votes
  static Future<void> _syncVoteCounts(List<CandidateModel> candidates) async {
    await _loadVotes();
    final voteCounts = <int, int>{};
    for (var vote in _votes) {
      voteCounts[vote.candidateId] = (voteCounts[vote.candidateId] ?? 0) + 1;
    }
    for (int i = 0; i < candidates.length; i++) {
      candidates[i] = candidates[i].copyWith(
        voteCount: voteCounts[candidates[i].id] ?? 0,
      );
    }
    // Save synced candidates
    await _saveCandidates(candidates);
  }

  // Save candidates to storage
  static Future<void> _saveCandidates(List<CandidateModel> candidates) async {
    try {
      // Save using PersistentStorageService (more robust with compression & backup)
      final success = await PersistentStorageService.saveCandidates(candidates);
      if (success) {
        debugPrint('[VotingService] ✓ Candidates saved successfully using PersistentStorage');
      } else {
        debugPrint('[VotingService] ⚠ Failed to save using PersistentStorage, trying LocalStorage...');
        // Fallback to LocalStorage
        final jsonList = candidates.map((c) => c.toJson()).toList();
        await LocalStorage.setString(_candidatesKey, jsonEncode(jsonList));
      }
    } catch (e) {
      debugPrint('[VotingService] ✗ Error saving candidates: $e');
      // Final fallback
      try {
        final jsonList = candidates.map((c) => c.toJson()).toList();
        await LocalStorage.setString(_candidatesKey, jsonEncode(jsonList));
      } catch (e2) {
        debugPrint('[VotingService] ✗ All save attempts failed: $e2');
      }
    }
  }

  // Add new candidate
  static Future<void> addCandidate(CandidateModel candidate) async {
    final candidates = await getCandidates();

    final exists = candidates.any((c) => c.id == candidate.id);
    if (exists) {
      return;
    }

    candidates.add(candidate);
    await _saveCandidates(candidates);
  }

  // Update candidate
  static Future<void> updateCandidate(CandidateModel candidate) async {
    final candidates = await getCandidates();
    final index = candidates.indexWhere((c) => c.id == candidate.id);
    if (index != -1) {
      candidates[index] = candidate;
      await _saveCandidates(candidates);
    }
  }

  // Delete candidate
  static Future<void> deleteCandidate(int candidateId) async {
    final candidates = await getCandidates();
    candidates.removeWhere((c) => c.id == candidateId);
    await _saveCandidates(candidates);
  }

  // Get candidate by id
  static Future<CandidateModel?> getCandidateById(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final candidates = await getCandidates();
    try {
      return candidates.firstWhere((candidate) => candidate.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get all vote records
  static Future<List<VoteModel>> getVotes() async {
    await _loadVotes();
    return List<VoteModel>.from(_votes);
  }

  // Get vote by id
  static Future<VoteModel?> getVoteById(String voteId) async {
    await _loadVotes();
    try {
      return _votes.firstWhere((vote) => vote.id == voteId);
    } catch (e) {
      return null;
    }
  }

  // Reset user's vote without deleting the user
  static Future<void> resetUserVote(String userId) async {
    await _loadVotes();
    try {
      final vote = _votes.firstWhere((vote) => vote.userId == userId);
      await deleteVote(vote.id);
    } catch (e) {
      // no vote to reset
    }
  }

  // Update an existing vote record by changing candidate
  static Future<void> updateVote(String voteId, int newCandidateId) async {
    await _loadVotes();
    final voteIndex = _votes.indexWhere((vote) => vote.id == voteId);
    if (voteIndex == -1) {
      throw VotingException(
        message: 'Vote tidak ditemukan',
        code: 'VOTE_NOT_FOUND',
      );
    }

    final vote = _votes[voteIndex];
    if (vote.candidateId == newCandidateId) {
      return;
    }

    final candidates = await getCandidates();
    final oldCandidateIndex = candidates.indexWhere((c) => c.id == vote.candidateId);
    final newCandidateIndex = candidates.indexWhere((c) => c.id == newCandidateId);

    if (oldCandidateIndex != -1) {
      final oldCandidate = candidates[oldCandidateIndex];
      candidates[oldCandidateIndex] = oldCandidate.copyWith(
        voteCount: oldCandidate.voteCount > 0 ? oldCandidate.voteCount - 1 : 0,
      );
    }

    if (newCandidateIndex == -1) {
      throw VotingException(
        message: 'Kandidat tujuan tidak ditemukan',
        code: 'CANDIDATE_NOT_FOUND',
      );
    }

    final newCandidate = candidates[newCandidateIndex];
    candidates[newCandidateIndex] = newCandidate.copyWith(
      voteCount: newCandidate.voteCount + 1,
    );

    _votes[voteIndex] = vote.copyWith(
      candidateId: newCandidateId,
      votedAt: DateTime.now(),
    );

    await _saveCandidates(candidates);
    await _saveVotes();
  }

  // Delete vote record and optionally reset voting status
  static Future<void> deleteVote(String voteId) async {
    await _loadVotes();
    final voteIndex = _votes.indexWhere((vote) => vote.id == voteId);
    if (voteIndex == -1) {
      throw VotingException(
        message: 'Vote tidak ditemukan',
        code: 'VOTE_NOT_FOUND',
      );
    }

    final vote = _votes[voteIndex];
    final candidates = await getCandidates();
    final candidateIndex = candidates.indexWhere((c) => c.id == vote.candidateId);

    if (candidateIndex != -1) {
      final candidate = candidates[candidateIndex];
      candidates[candidateIndex] = candidate.copyWith(
        voteCount: candidate.voteCount > 0 ? candidate.voteCount - 1 : 0,
      );
      await _saveCandidates(candidates);
    }

    _votes.removeAt(voteIndex);
    await _saveVotes();
    await LocalStorage.remove(AppConstants.votedCandidateKey);

    // Jika admin menghapus vote, juga set status voter kembali
    await AuthService.setHasVotedById(vote.userId, false);
  }

  // Submit vote
  static Future<VoteModel> submitVote(
    String userId,
    int candidateId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final candidates = await getCandidates();

    // Check if user has already voted
    if (await hasUserVoted(userId)) {
      throw VotingException(
        message: AppConstants.alreadyVoted,
        code: 'ALREADY_VOTED',
      );
    }

    // Check if candidate exists
    final candidate = candidates.firstWhere(
      (c) => c.id == candidateId,
      orElse: () => throw VotingException(
        message: 'Kandidat tidak ditemukan',
        code: 'CANDIDATE_NOT_FOUND',
      ),
    );

    // Create vote record
    final vote = VoteModel(
      id: 'vote_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      candidateId: candidateId,
      votedAt: DateTime.now(),
      ipAddress: '192.168.1.1', // Dummy IP
    );

    // Update candidate vote count
    final updatedCandidate = candidate.copyWith(
      voteCount: candidate.voteCount + 1,
    );
    final candidateIndex = candidates.indexOf(candidate);
    candidates[candidateIndex] = updatedCandidate;

    // Save updated candidates
    await _saveCandidates(candidates);

    // Ensure no duplicate votes for this user (extra safety)
    _votes.removeWhere((v) => v.userId == userId);

    // Add vote to list and save to storage
    _votes.add(vote);
    await _saveVotes();

    // Update user's hasVoted status
    await AuthService.setHasVotedById(userId, true);

    return vote;
  }

  // Check if user has voted
  static Future<bool> hasUserVoted(String userId) async {
    await _loadVotes();
    return _votes.any((vote) => vote.userId == userId);
  }

  // Get user's vote
  static Future<VoteModel?> getUserVote(String userId) async {
    await _loadVotes();
    try {
      return _votes.firstWhere((vote) => vote.userId == userId);
    } catch (e) {
      return null;
    }
  }

  // Get vote results
  static Future<Map<int, int>> getVoteResults() async {
    await Future.delayed(const Duration(milliseconds: 400));

    await _loadVotes();
    final results = <int, int>{};
    for (var vote in _votes) {
      results[vote.candidateId] = (results[vote.candidateId] ?? 0) + 1;
    }
    return results;
  }

  // Get total votes
  static Future<int> getTotalVotes() async {
    await _loadVotes();
    return _votes.length;
  }

  // Get vote percentage for a candidate
  static Future<double> getVotePercentage(int candidateId) async {
    final candidates = await getCandidates();
    final totalVotes = await getTotalVotes();

    if (totalVotes == 0) return 0.0;

    final candidate = candidates.firstWhere(
      (c) => c.id == candidateId,
      orElse: () => CandidateModel(
        id: candidateId,
        name1: '',
        name2: '',
        visi: '',
        misi: '',
        photoUrl1: '',
        photoUrl2: '',
        voteCount: 0,
      ),
    );

    return (candidate.voteCount / totalVotes) * 100;
  }

  // Get candidates with vote counts
  static Future<List<CandidateModel>> getCandidatesWithVotes() async {
    return getCandidates();
  }

  // Reset voting data (for testing) - hanya reset vote counts dan votes, jangan hapus kandidat yang ditambahkan admin
  static Future<void> resetData() async {
    final candidates = await getCandidates();
    // Hanya reset voteCount menjadi 0, jangan ganti kandidat dengan default
    for (var i = 0; i < candidates.length; i++) {
      candidates[i] = candidates[i].copyWith(voteCount: 0);
    }
    await _saveCandidates(candidates);
    _votes.clear();
    await _saveVotes();
    await LocalStorage.remove(AppConstants.votedCandidateKey);
  }
}

