import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/level.dart';
import '../models/performance.dart';

class LevelController extends ChangeNotifier {
  List<Level> _levels = [];
  Level? _currentLevel;
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _currentLevelMCQs = [];
  Map<String, dynamic>? _currentPerformance;
  bool _isLoading = false;
  String? _error;

  List<Level> get levels => _levels;
  Level? get currentLevel => _currentLevel;
  List<Map<String, dynamic>> get questions => _questions;
  List<Map<String, dynamic>> get currentLevelMCQs => _currentLevelMCQs;
  Map<String, dynamic>? get currentPerformance => _currentPerformance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLevels() async {
    if (_isLoading) return; // Prevent multiple simultaneous calls
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final levelsData = await SupabaseService.getLevels();
      _levels = levelsData.map((data) => Level.fromMap(data)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLevelById(String levelId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final levelData = await SupabaseService.getLevelById(levelId);
      if (levelData != null) {
        _currentLevel = Level.fromMap(levelData);
        _questions = levelData['questions'] ?? [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMCQsForLevel(int levelId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final mcqsData = await SupabaseService.getMCQsForLevel(levelId);
      _currentLevelMCQs = mcqsData;
      
      print('📚 Loaded ${mcqsData.length} MCQs for level $levelId');
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading MCQs for level $levelId: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Performance>> getStudentPerformance(String studentId) async {
    try {
      // This would typically fetch from a performance table
      // For now, return a mock performance list with level information
      final mockPerformance = Performance(
        id: 1,
        studentId: studentId,
        levelId: 1,
        score: 85,
        totalQuestions: 10,
        correctAnswers: 8,
        timeTaken: 300,
        answers: [],
        completedAt: DateTime.now(),
        level: {
          'id': 1,
          'level_number': 1,
          'title': 'C Programming Basics',
          'description': 'Basic concepts of C programming',
        },
      );
      
      // Don't overwrite _currentPerformance with mock data
      // _currentPerformance = mockPerformance.toMap();
      return [mockPerformance];
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  Future<bool> submitMCQTest({
    required String studentId,
    required int levelId,
    required List<Map<String, dynamic>> answers,
    required int timeTaken,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await SupabaseService.submitMCQTest(
        levelId: levelId.toString(),
        answers: answers.map((a) => a['selected_answer'] as int).toList(),
      );
      
      // Calculate performance
      final correctAnswers = answers.where((answer) => answer['selected_answer'] == 1).length;
      final totalQuestions = _currentLevelMCQs.length; // Use actual total questions from level
      final score = (correctAnswers / totalQuestions) * 100;
      
      print('📊 Performance calculation:');
      print('   _currentLevelMCQs length: ${_currentLevelMCQs.length}');
      print('   Total questions in level: $totalQuestions');
      print('   Answers submitted: ${answers.length}');
      print('   Correct answers: $correctAnswers');
      print('   Score: ${score.toInt()}%');
      
      if (_currentLevelMCQs.isEmpty) {
        print('❌ WARNING: _currentLevelMCQs is empty! This will cause issues.');
      }
      
      // Get level information
      final levelData = await SupabaseService.getLevelById(levelId.toString());
      
      final performance = Performance(
        id: 1,
        studentId: studentId,
        levelId: levelId,
        score: score.toInt(),
        totalQuestions: totalQuestions, // Use actual total questions
        correctAnswers: correctAnswers,
        timeTaken: timeTaken,
        answers: answers,
        completedAt: DateTime.now(),
        level: levelData,
      );
      
      _currentPerformance = performance.toMap();
      
      print('📊 Final performance data stored:');
      print('   _currentPerformance: $_currentPerformance');
      if (_currentPerformance != null) {
        print('   Score: ${_currentPerformance!['score']}');
        print('   Total questions: ${_currentPerformance!['total_questions']}');
        print('   Correct answers: ${_currentPerformance!['correct_answers']}');
        print('   Time taken: ${_currentPerformance!['time_taken']}');
      } else {
        print('   ❌ _currentPerformance is null!');
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 