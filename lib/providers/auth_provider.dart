import 'package:flutter/material.dart';
import 'package:pemilihan_ketua_kelas_informatika/models/user_model.dart';
import 'package:pemilihan_ketua_kelas_informatika/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;
  Map<String, UserModel> get dummyUsers => AuthService.dummyUsers;

  AuthProvider() {
    _checkLoginStatus();
  }

  void _checkLoginStatus() {
    _currentUser = AuthService.getCurrentUser();
    _isLoggedIn = AuthService.isLoggedIn();
    notifyListeners();
  }

  Future<bool> login(String nim, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await AuthService.login(nim, password);
      _currentUser = user;
      _isLoggedIn = true;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoggedIn = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.logout();
      _currentUser = null;
      _isLoggedIn = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkHasVoted() async {
    if (_currentUser != null) {
      final hasVoted = await AuthService.hasVotedById(_currentUser!.id);
      if (hasVoted) {
        await AuthService.setHasVoted(_currentUser!.nim, true);
        _currentUser = _currentUser!.copyWith(hasVoted: true);
      }
      notifyListeners();
    }
  }

  Future<bool> register(
    String name,
    String nim,
    String email,
    String phoneNumber,
    String password,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await AuthService.register(
        name,
        nim,
        email,
        phoneNumber,
        password,
      );
      _currentUser = user;
      _isLoggedIn = true;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoggedIn = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setHasVoted(bool hasVoted) async {
    if (_currentUser != null) {
      await AuthService.setHasVoted(_currentUser!.nim, hasVoted);
      _currentUser = _currentUser!.copyWith(hasVoted: hasVoted);
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

