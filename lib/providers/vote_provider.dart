import 'package:flutter/material.dart';
import 'package:pemilihan_ketua_kelas_informatika/models/vote_model.dart';
import 'package:pemilihan_ketua_kelas_informatika/services/voting_service.dart';

class VoteProvider extends ChangeNotifier {
  VoteModel? _currentVote;
  Map<int, int> _voteResults = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasVoted = false;
  int _totalVotes = 0;

  VoteModel? get currentVote => _currentVote;
  Map<int, int> get voteResults => _voteResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasVoted => _hasVoted;
  int get totalVotes => _totalVotes;

  Future<bool> submitVote(String userId, int candidateId) async {
    // Prevent duplicate voting
    if (_hasVoted) {
      _errorMessage = 'Anda sudah melakukan voting';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final vote = await VotingService.submitVote(userId, candidateId);
      _currentVote = vote;
      _hasVoted = true;
      _totalVotes = await VotingService.getTotalVotes();
      await fetchVoteResults();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchVoteResults() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _voteResults = await VotingService.getVoteResults();
      _totalVotes = await VotingService.getTotalVotes();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkUserVoted(String userId) async {
    _hasVoted = await VotingService.hasUserVoted(userId);
    _currentVote = await VotingService.getUserVote(userId);
    notifyListeners();
  }

  Future<void> deleteVote(String voteId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await VotingService.deleteVote(voteId);
      await fetchVoteResults();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateVote(String voteId, int newCandidateId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await VotingService.updateVote(voteId, newCandidateId);
      await fetchVoteResults();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetVote(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await VotingService.resetUserVote(userId);
      await fetchVoteResults();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<double> getVotePercentage(int candidateId) async {
    return await VotingService.getVotePercentage(candidateId);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

