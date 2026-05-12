import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pemilihan_ketua_kelas_informatika/models/candidate_model.dart';
import 'local_storage.dart';

/// Service untuk menyimpan data kandidat secara permanen menggunakan Hive.
/// Data tetap tersedia setelah refresh browser, logout/login ulang, atau aplikasi ditutup.
class PersistentStorageService {
  static const String _boxName = 'candidate_storage';
  static const String _dataKey = 'candidates_data';
  static const String _metadataKey = 'candidates_metadata';
  static const String _legacyCandidatesKey = 'candidates';

  static late Box _box;
  static bool _isInitialized = false;

  /// Initialize Hive storage service
  static Future<void> init() async {
    if (_isInitialized) return;
    await LocalStorage.init();
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    _isInitialized = true;
    debugPrint('[PersistentStorage] Hive initialized, box opened');
  }

  /// Save candidates secara permanen ke Hive.
  static Future<bool> saveCandidates(List<CandidateModel> candidates) async {
    final jsonList = candidates.map((c) => c.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    try {
      await init();
      debugPrint('[PersistentStorage] Saving ${candidates.length} candidates...');

      await _box.put(_dataKey, jsonString);
      await _box.put(
        _metadataKey,
        jsonEncode({
          'timestamp': DateTime.now().toIso8601String(),
          'count': candidates.length,
          'size': jsonString.length,
          'platform': defaultTargetPlatform.toString(),
          'storage': 'hive',
        }),
      );

      debugPrint('[PersistentStorage] ✓ Candidates saved to Hive');
      return true;
    } catch (e) {
      debugPrint('[PersistentStorage] ✗ Error saving candidates to Hive: $e');
      try {
        debugPrint('[PersistentStorage] Trying SharedPreferences fallback');
        await LocalStorage.setString(_legacyCandidatesKey, jsonString);
        debugPrint('[PersistentStorage] ✓ Candidates saved to SharedPreferences fallback');
        return true;
      } catch (fallbackError) {
        debugPrint('[PersistentStorage] ✗ Fallback save failed: $fallbackError');
        return false;
      }
    }
  }

  /// Load candidates dari Hive.
  static Future<List<CandidateModel>?> loadCandidates() async {
    try {
      await init();
      debugPrint('[PersistentStorage] Loading candidates from Hive...');

      if (!_box.containsKey(_dataKey)) {
        debugPrint('[PersistentStorage] No candidate data found in Hive');
        final legacyData = LocalStorage.getString(_legacyCandidatesKey);
        if (legacyData != null && legacyData.isNotEmpty) {
          debugPrint('[PersistentStorage] Loading candidates from SharedPreferences fallback');
          final jsonList = jsonDecode(legacyData) as List<dynamic>;
          return jsonList
              .map((json) => CandidateModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return null;
      }

      final rawData = _box.get(_dataKey);
      if (rawData == null || rawData is! String || rawData.isEmpty) {
        debugPrint('[PersistentStorage] Candidate data is empty or invalid');
        final legacyData = LocalStorage.getString(_legacyCandidatesKey);
        if (legacyData != null && legacyData.isNotEmpty) {
          debugPrint('[PersistentStorage] Loading candidates from SharedPreferences fallback');
          final jsonList = jsonDecode(legacyData) as List<dynamic>;
          return jsonList
              .map((json) => CandidateModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return null;
      }

      final jsonList = jsonDecode(rawData) as List<dynamic>;
      final candidates = jsonList
          .map((json) => CandidateModel.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint(
          '[PersistentStorage] ✓ Loaded ${candidates.length} candidates from Hive');
      return candidates;
    } catch (e) {
      debugPrint('[PersistentStorage] ✗ Error loading candidates from Hive: $e');
      final legacyData = LocalStorage.getString(_legacyCandidatesKey);
      if (legacyData != null && legacyData.isNotEmpty) {
        try {
          debugPrint('[PersistentStorage] Loading candidates from SharedPreferences fallback');
          final jsonList = jsonDecode(legacyData) as List<dynamic>;
          return jsonList
              .map((json) => CandidateModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } catch (fallbackError) {
          debugPrint('[PersistentStorage] ✗ Fallback load failed: $fallbackError');
        }
      }
      return null;
    }
  }

  /// Get storage info untuk debugging.
  static Future<Map<String, dynamic>> getStorageInfo() async {
    await init();
    try {
      final hasData = _box.containsKey(_dataKey);
      final metadata = _box.get(_metadataKey);
      return {
        'hasData': hasData,
        'metadata': metadata != null ? jsonDecode(metadata) : null,
        'storageEngine': 'hive',
        'platform': defaultTargetPlatform.toString(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Clear all candidate data from Hive.
  static Future<bool> clearCandidates() async {
    try {
      await init();
      await _box.delete(_dataKey);
      await _box.delete(_metadataKey);
      await LocalStorage.remove(_legacyCandidatesKey);
      debugPrint('[PersistentStorage] ✓ Cleared candidate data from Hive and fallback storage');
      return true;
    } catch (e) {
      debugPrint('[PersistentStorage] ✗ Error clearing candidate data: $e');
      return false;
    }
  }
}
