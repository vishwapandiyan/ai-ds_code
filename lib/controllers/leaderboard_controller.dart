import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/leaderboard.dart';

class LeaderboardController extends ChangeNotifier {
  List<LeaderboardEntry> _levelLeaderboard = [];
  List<LeaderboardEntry> _globalLeaderboard = [];
  List<LeaderboardEntry> _studentLeaderboard = [];
  bool _isLoading = false;
  String? _error;
  int _selectedLevelId = 1;

  // Getters
  List<LeaderboardEntry> get levelLeaderboard => _levelLeaderboard;
  List<LeaderboardEntry> get globalLeaderboard => _globalLeaderboard;
  List<LeaderboardEntry> get studentLeaderboard => _studentLeaderboard;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedLevelId => _selectedLevelId;

  // Set selected level
  void setSelectedLevel(int levelId) {
    _selectedLevelId = levelId;
    notifyListeners();
    loadLevelLeaderboard(levelId);
  }

  // Load leaderboard for a specific level
  Future<void> loadLevelLeaderboard(int levelId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final leaderboard = await SupabaseService.getLeaderboardForLevel(levelId);
      _levelLeaderboard = leaderboard;
      
      print('🏆 Level leaderboard loaded: ${leaderboard.length} entries');
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading level leaderboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load global leaderboard
  Future<void> loadGlobalLeaderboard() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Debug the current state
      await SupabaseService.debugLeaderboard();

      final leaderboard = await SupabaseService.getGlobalLeaderboard();
      _globalLeaderboard = leaderboard;
      
      print('🏆 Global leaderboard loaded: ${leaderboard.length} entries');
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading global leaderboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load leaderboard for a specific student
  Future<void> loadStudentLeaderboard(String studentId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final leaderboard = await SupabaseService.getStudentLeaderboard(studentId);
      _studentLeaderboard = leaderboard;
      
      print('🏆 Student leaderboard loaded: ${leaderboard.length} entries');
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading student leaderboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update leaderboard when a student completes a test
  Future<void> updateLeaderboard({
    required String studentId,
    required int levelId,
    required int score,
    required int timeTaken,
  }) async {
    try {
      await SupabaseService.updateLeaderboard(
        studentId: studentId,
        levelId: levelId,
        score: score,
        timeTaken: timeTaken,
      );
      
      // Refresh the relevant leaderboards
      if (_selectedLevelId == levelId) {
        await loadLevelLeaderboard(levelId);
      }
      await loadGlobalLeaderboard();
      
      print('✅ Leaderboard updated successfully');
    } catch (e) {
      _error = e.toString();
      print('❌ Error updating leaderboard: $e');
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get available levels for leaderboard
  List<int> get availableLevels {
    final levels = <int>{};
    for (final entry in _globalLeaderboard) {
      levels.add(entry.levelId);
    }
    return levels.toList()..sort();
  }

  // Get student's best performance
  LeaderboardEntry? getStudentBestPerformance(String studentId) {
    if (_globalLeaderboard.isEmpty) return null;
    
    try {
      return _globalLeaderboard.firstWhere(
        (entry) => entry.studentId == studentId,
        orElse: () => _globalLeaderboard.first,
      );
    } catch (e) {
      return null;
    }
  }

  // Get student's rank in a specific level
  int? getStudentRankInLevel(String studentId, int levelId) {
    try {
      final entry = _levelLeaderboard.firstWhere(
        (entry) => entry.studentId == studentId && entry.levelId == levelId,
      );
      return entry.rankPosition;
    } catch (e) {
      return null;
    }
  }
}
