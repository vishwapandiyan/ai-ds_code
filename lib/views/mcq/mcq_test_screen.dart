import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../controllers/auth_controller.dart';
import '../../controllers/level_controller.dart';
import '../../controllers/leaderboard_controller.dart';
import '../../models/level.dart';

import '../../widgets/custom_button.dart';
import 'result_screen.dart';

class MCQTestScreen extends StatefulWidget {
  final Level level;

  const MCQTestScreen({super.key, required this.level});

  @override
  State<MCQTestScreen> createState() => _MCQTestScreenState();
}

class _MCQTestScreenState extends State<MCQTestScreen> {
  int _currentQuestionIndex = 0;
  int _timeElapsed = 0;
  Timer? _timer;
  List<Map<String, dynamic>> _answers = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMCQs();
    });
  }

  Future<void> _loadMCQs() async {
    print('📚 Loading MCQs for level ${widget.level.id}');
    final levelController = context.read<LevelController>();
    await levelController.loadMCQsForLevel(widget.level.id);
    print('📚 MCQs loaded: ${levelController.currentLevelMCQs.length}');
    _initializeAnswers();
    setState(() {}); // Trigger rebuild to show MCQs
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeElapsed++;
      });
    });
  }

  void _initializeAnswers() {
    final levelController = context.read<LevelController>();
    print('📝 Initializing answers...');
    print('📝 Current MCQs count: ${levelController.currentLevelMCQs.length}');
    if (levelController.currentLevelMCQs.isNotEmpty) {
      _answers = List.generate(
        levelController.currentLevelMCQs.length,
        (index) => {'question_index': index, 'selected_answer': -1},
      );
      print('📝 Initialized answers for ${_answers.length} questions');
      print('📝 Total MCQs in level: ${levelController.currentLevelMCQs.length}');
    } else {
      print('❌ No MCQs available for level');
    }
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      _answers[_currentQuestionIndex]['selected_answer'] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < context.read<LevelController>().currentLevelMCQs.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _submitTest() async {
    if (_isSubmitting) return;

    // Check if all questions are answered
    final unansweredQuestions = _answers.where((answer) => answer['selected_answer'] == -1).length;
    if (unansweredQuestions > 0) {
      final shouldSubmit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unanswered Questions'),
          content: Text('You have $unansweredQuestions unanswered questions. Do you want to submit anyway?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Review'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );

      if (shouldSubmit != true) return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final levelController = context.read<LevelController>();
    final authController = context.read<AuthController>();
    final user = authController.currentUser;

    print('📝 Submitting test with ${_answers.length} answers');
    print('📝 Time taken: $_timeElapsed seconds');
    print('📝 Current MCQs count: ${levelController.currentLevelMCQs.length}');
    print('📝 Answers structure: ${_answers.take(3).toList()}'); // Show first 3 answers

    if (user != null) {
      final success = await levelController.submitMCQTest(
        studentId: user.id,
        levelId: widget.level.id,
        answers: _answers,
        timeTaken: _timeElapsed,
      );

      if (success && mounted) {
        _timer?.cancel();
        
        // Update leaderboard
        try {
          final leaderboardController = context.read<LeaderboardController>();
          final performance = levelController.currentPerformance;
          if (performance != null) {
            await leaderboardController.updateLeaderboard(
              studentId: user.id,
              levelId: widget.level.id,
              score: performance['score'] ?? 0,
              timeTaken: performance['time_taken'] ?? _timeElapsed,
            );
          }
        } catch (e) {
          print('❌ Error updating leaderboard: $e');
        }
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              performance: levelController.currentPerformance!,
              mcqQuestions: levelController.currentLevelMCQs,
              studentAnswers: _answers,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(levelController.error ?? 'Failed to submit test'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LevelController>(
      builder: (context, levelController, child) {
        if (levelController.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (levelController.currentLevelMCQs.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Level ${widget.level.levelNumber} - ${widget.level.title}'),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No questions available for this level'),
                  SizedBox(height: 8),
                  Text('Please contact your administrator'),
                ],
              ),
            ),
          );
        }

        final currentMCQ = levelController.currentLevelMCQs[_currentQuestionIndex];
        final totalQuestions = levelController.currentLevelMCQs.length;
        final progress = (_currentQuestionIndex + 1) / totalQuestions;

        return Scaffold(
          appBar: AppBar(
            title: Text('Level ${widget.level.levelNumber} - ${widget.level.title}'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(_timeElapsed ~/ 60).toString().padLeft(2, '0')}:${(_timeElapsed % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              
              // Question Counter
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1} of $totalQuestions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${((_currentQuestionIndex + 1) / totalQuestions * 100).toInt()}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Question Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Text
                      Text(
                        currentMCQ['question'] ?? 'Question not available',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Answer Options
                      ...(currentMCQ['options'] as List<dynamic>? ?? []).asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        final isSelected = _answers[_currentQuestionIndex]['selected_answer'] == index;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _selectAnswer(index),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? Colors.white : Colors.grey.shade300,
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, size: 16, color: Colors.blue)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              // Navigation Buttons
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomButton(
                      text: 'Previous',
                      onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                      width: 120,
                      backgroundColor: Colors.grey,
                    ),
                    CustomButton(
                      text: _currentQuestionIndex < totalQuestions - 1 ? 'Next' : 'Submit',
                      onPressed: _isSubmitting ? null : (_currentQuestionIndex < totalQuestions - 1 ? _nextQuestion : _submitTest),
                      width: 120,
                      isLoading: _isSubmitting,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 