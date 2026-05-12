import 'package:flutter/material.dart';
import 'package:pemilihan_ketua_kelas_informatika/models/candidate_model.dart';
import 'package:pemilihan_ketua_kelas_informatika/services/voting_service.dart';

class CandidateProvider extends ChangeNotifier {
  List<CandidateModel> _candidates = [];
  bool _isLoading = false;
  String? _errorMessage;
  CandidateModel? _selectedCandidate;

  List<CandidateModel> get candidates => _candidates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CandidateModel? get selectedCandidate => _selectedCandidate;

  Future<void> fetchCandidates() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _candidates = await VotingService.getCandidates();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Preload candidates data on app start
  Future<void> preloadCandidates() async {
    if (_candidates.isEmpty) {
      await fetchCandidates();
    }
  }

  void selectCandidate(CandidateModel candidate) {
    _selectedCandidate = candidate;
    notifyListeners();
  }

  void clearSelectedCandidate() {
    _selectedCandidate = null;
    notifyListeners();
  }

  Future<CandidateModel?> getCandidateById(int id) async {
    try {
      return await VotingService.getCandidateById(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> addCandidate(CandidateModel candidate) async {
    final existingIndex = _candidates.indexWhere((c) => c.id == candidate.id);
    if (existingIndex != -1) {
      _candidates[existingIndex] = candidate;
      await VotingService.updateCandidate(candidate);
    } else {
      _candidates.add(candidate);
      await VotingService.addCandidate(candidate);
    }
    notifyListeners();
  }

  Future<void> updateCandidate(CandidateModel candidate) async {
    final index = _candidates.indexWhere((c) => c.id == candidate.id);
    if (index != -1) {
      _candidates[index] = candidate;
      await VotingService.updateCandidate(candidate);
      notifyListeners();
    }
  }

  Future<void> deleteCandidate(int candidateId) async {
    _candidates.removeWhere((c) => c.id == candidateId);
    await VotingService.deleteCandidate(candidateId);
    if (_selectedCandidate?.id == candidateId) {
      _selectedCandidate = null;
    }
    notifyListeners();
  }
}
