import 'dart:convert';
import 'package:pemilihan_ketua_kelas_informatika/models/user_model.dart';
import 'package:pemilihan_ketua_kelas_informatika/models/vote_model.dart';
import 'package:pemilihan_ketua_kelas_informatika/utils/constants.dart';
import 'package:pemilihan_ketua_kelas_informatika/utils/exceptions.dart';
import 'local_storage.dart';

class AuthService {
  static const String defaultPassword = 'informatika 2024';
  static const String adminUsername = 'admin';
  static const String adminPassword = defaultPassword;
  static const String _votesKey = 'votes';

  static final List<String> dummyNIM = List.generate(
    40,
    (index) => '202423${(1 + index).toString().padLeft(4, '0')}',
  );

  static final Map<String, UserModel> dummyUsers = _generateDummyUsers();
  static final Map<String, String> dummyPasswords = Map.fromEntries(
    dummyNIM.map((nim) => MapEntry(nim, defaultPassword)),
  )..[adminUsername] = adminPassword;

  static Map<String, UserModel> _generateDummyUsers() {
    final users = <String, UserModel>{};
    for (int i = 0; i < dummyNIM.length; i++) {
      final nim = dummyNIM[i];
      users[nim] = UserModel(
        id: (i + 1).toString(),
        nim: nim,
        name: 'Mahasiswa ${i + 1}',
        email: 'mahasiswa$nim@informatika4a.ac.id',
        phoneNumber: '08123456${(7890 + i).toString().padLeft(4, '0')}',
        createdAt: DateTime.now(),
        hasVoted: false,
        role: 'voter',
      );
    }
    users[adminUsername] = UserModel(
      id: 'admin',
      nim: adminUsername,
      name: 'Administrator',
      email: 'admin@informatika4a.ac.id',
      phoneNumber: '081234567890',
      createdAt: DateTime.now(),
      hasVoted: false,
      role: 'admin',
    );
    return users;
  }

  static Future<UserModel> login(String nim, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (!_isValidLoginNim(nim)) {
      throw AuthException(
        message: 'NIM atau username tidak terdaftar',
        code: 'USER_NOT_FOUND',
      );
    }

    if (dummyPasswords[nim] != password) {
      throw AuthException(
        message: 'Password salah',
        code: 'INVALID_PASSWORD',
      );
    }

    final user = dummyUsers[nim];
    if (user == null) {
      throw AuthException(
        message: 'User tidak ditemukan',
        code: 'USER_NOT_FOUND',
      );
    }

    final updatedUser = await _syncUserVoteStatus(user);
    await _saveCurrentUser(updatedUser);
    await LocalStorage.setString(AppConstants.tokenKey, 'dummy_token_$nim');
    return updatedUser;
  }

  static Future<void> logout() async {
    await LocalStorage.remove(AppConstants.userKey);
    await LocalStorage.remove(AppConstants.tokenKey);
    await LocalStorage.remove(AppConstants.votedCandidateKey);
  }

  static UserModel? getCurrentUser() {
    final userData = LocalStorage.getJson(AppConstants.userKey);
    if (userData != null) {
      return UserModel.fromJson(userData);
    }
    return null;
  }

  static bool isLoggedIn() {
    return LocalStorage.containsKey(AppConstants.userKey);
  }

  static String? getToken() {
    return LocalStorage.getString(AppConstants.tokenKey);
  }

  static Future<void> setHasVoted(String nim, bool hasVoted) async {
    final user = dummyUsers[nim];
    if (user != null) {
      final updatedUser = user.copyWith(hasVoted: hasVoted);
      dummyUsers[nim] = updatedUser;
      final currentUser = getCurrentUser();
      if (currentUser != null && currentUser.nim == nim) {
        await _saveCurrentUser(updatedUser);
      }
    }
  }

  static Future<bool> _hasUserVotedById(String userId) async {
    final savedData = LocalStorage.getString(_votesKey);
    if (savedData == null || savedData.isEmpty) {
      return false;
    }

    try {
      final List<dynamic> jsonList = jsonDecode(savedData);
      final votes = jsonList
          .map((json) => VoteModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return votes.any((vote) => vote.userId == userId);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasVotedById(String userId) async {
    return await _hasUserVotedById(userId);
  }

  static Future<UserModel> _syncUserVoteStatus(UserModel user) async {
    if (user.role == 'admin') return user;

    final hasVoted = await _hasUserVotedById(user.id);
    if (hasVoted && !user.hasVoted) {
      final updatedUser = user.copyWith(hasVoted: true);
      dummyUsers[user.nim] = updatedUser;
      return updatedUser;
    }
    return user;
  }

  static UserModel? getUserById(String id) {
    try {
      return dummyUsers.values.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<void> setHasVotedById(String userId, bool hasVoted) async {
    final user = getUserById(userId);
    if (user != null) {
      await setHasVoted(user.nim, hasVoted);
    }
  }

  static bool hasVoted() {
    final currentUser = getCurrentUser();
    return currentUser?.hasVoted ?? false;
  }

  static Future<UserModel> register(
    String name,
    String nim,
    String email,
    String phoneNumber,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (dummyUsers.containsKey(nim)) {
      throw AuthException(
        message: 'NIM sudah terdaftar',
        code: 'NIM_ALREADY_EXISTS',
      );
    }

    if (!isValidNIM(nim)) {
      throw AuthException(
        message: 'NIM tidak valid untuk kelas Informatika 4A',
        code: 'INVALID_NIM',
      );
    }

    final newUser = UserModel(
      id: (dummyUsers.length + 1).toString(),
      nim: nim,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      createdAt: DateTime.now(),
      hasVoted: false,
    );

    dummyUsers[nim] = newUser;
    dummyNIM.add(nim);
    dummyPasswords[nim] = password;

    return newUser;
  }

  static bool _isValidLoginNim(String nim) {
    return nim == adminUsername || dummyNIM.contains(nim);
  }

  static bool isValidNIM(String nim) {
    if (nim.length != 10 || !RegExp(r'^\d{10}$').hasMatch(nim)) {
      return false;
    }

    final numeric = int.tryParse(nim);
    if (numeric == null) return false;

    return numeric >= 2024230001 && numeric <= 2024230040;
  }

  static Future<void> _saveCurrentUser(UserModel user) async {
    await LocalStorage.setJson(AppConstants.userKey, user.toJson());
  }
}

