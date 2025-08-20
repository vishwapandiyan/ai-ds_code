import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../services/supabase_service.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> performance;
  final List<Map<String, dynamic>>? mcqQuestions;
  final List<Map<String, dynamic>>? studentAnswers;

  const ResultScreen({
    super.key, 
    required this.performance,
    this.mcqQuestions,
    this.studentAnswers,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  List<Map<String, dynamic>>? _mcqQuestions;
  bool _isLoadingMCQs = false;

  @override
  void initState() {
    super.initState();
    _initializeMCQs();
  }

  void _initializeMCQs() {
    if (widget.mcqQuestions != null) {
      _mcqQuestions = widget.mcqQuestions;
    } else {
      _fetchMCQsFromDatabase();
    }
  }

  Future<void> _fetchMCQsFromDatabase() async {
    if (_isLoadingMCQs) return;
    
    setState(() {
      _isLoadingMCQs = true;
    });

    try {
      final levelId = widget.performance['level_id']?.toString() ?? 
                     widget.performance['levels']?['id']?.toString();
      
      if (levelId != null) {
        final mcqs = await SupabaseService.getMCQsForLevel(int.parse(levelId));
        setState(() {
          _mcqQuestions = mcqs;
        });
      }
    } catch (e) {
      print('❌ Error fetching MCQs: $e');
    } finally {
      setState(() {
        _isLoadingMCQs = false;
      });
    }
  }

  bool get passed {
    final score = widget.performance['score'];
    if (score is int) return score >= 70;
    if (score is double) return score >= 70;
    return false;
  }
  int get score {
    final score = widget.performance['score'];
    if (score is int) return score;
    if (score is double) return score.toInt();
    return 0;
  }
  int get correctAnswers => widget.performance['correct_answers'] as int? ?? 0;
  int get totalQuestions => widget.performance['total_questions'] as int? ?? 0;
  int get timeTaken => widget.performance['time_taken'] as int? ?? 0;

  @override
  Widget build(BuildContext context) {
    // Debug logging to see what's in the performance data
    print('🔍 Result Screen - Performance Data:');
    print('   Raw performance: ${widget.performance}');
    print('   Score: ${widget.performance['score']}');
    print('   Correct answers: ${widget.performance['correct_answers']}');
    print('   Total questions: ${widget.performance['total_questions']}');
    print('   Time taken: ${widget.performance['time_taken']}');
    print('   Calculated score: $score');
    print('   Calculated correctAnswers: $correctAnswers');
    print('   Calculated totalQuestions: $totalQuestions');
    print('   Calculated timeTaken: $timeTaken');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Result Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: passed 
                      ? [Colors.green, Colors.green.shade700]
                      : [Colors.red, Colors.red.shade700],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    passed ? Icons.check_circle : Icons.cancel,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    passed ? 'Congratulations!' : 'Keep Trying!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    passed 
                        ? 'You passed the test!'
                        : 'You need 70% to pass. Keep practicing!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Score Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Score Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildScoreItem(
                          'Correct',
                          '${correctAnswers}',
                          Colors.green,
                        ),
                        _buildScoreItem(
                          'Incorrect',
                          '${totalQuestions - correctAnswers}',
                          Colors.red,
                        ),
                        _buildScoreItem(
                          'Total',
                          '${totalQuestions}',
                          Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Percentage: ',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${(score / totalQuestions * 100).toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: passed ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time and Level Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Test Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Level', '${widget.performance['levels']?['level_number'] ?? 'Unknown'}'),
                    _buildDetailRow('Time Taken', _formatTime(timeTaken)),
                    _buildDetailRow('Completed', _formatDate(widget.performance['completed_at'] != null 
                        ? DateTime.parse(widget.performance['completed_at']) 
                        : DateTime.now())),
                    if (widget.performance['levels'] != null)
                      _buildDetailRow('Level Title', widget.performance['levels']!['title'] ?? 'Unknown'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Wrong Answers Section
            if (_isLoadingMCQs) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      Text(
                        'Loading questions for review...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ] else if (_mcqQuestions != null && _mcqQuestions!.isNotEmpty) ...[
              if (wrongAnswers.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Questions to Review (${wrongAnswers.length})',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Review these questions to improve your understanding:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...wrongAnswers.map((wrongAnswer) => _buildWrongAnswerCard(wrongAnswer)),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Perfect Score! 🎉',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All answers are correct. Great job!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ] else ...[
              // MCQs failed to load or are empty
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.orange,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to Load Questions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Questions for review could not be loaded.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchMCQsFromDatabase,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Back to Dashboard',
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    backgroundColor: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Try Again',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  // Get wrong answers with explanations
  List<Map<String, dynamic>> get wrongAnswers {
    if (_mcqQuestions == null) return [];
    
    // Use studentAnswers from widget if available, otherwise use performance answers
    final answers = widget.studentAnswers ?? 
                   (widget.performance['answers'] as List<dynamic>? ?? [])
                       .map((a) => Map<String, dynamic>.from(a))
                       .toList();
    
    if (answers.isEmpty) return [];
    
    List<Map<String, dynamic>> wrong = [];
    
    for (int i = 0; i < _mcqQuestions!.length; i++) {
      if (i < answers.length) {
        final question = _mcqQuestions![i];
        final studentAnswer = answers[i];
        final correctAnswerIndex = question['correct_answer'] as int? ?? 0;
        final studentAnswerIndex = studentAnswer['selected_answer'] as int? ?? -1;
        
        if (studentAnswerIndex != correctAnswerIndex) {
          wrong.add({
            'question': question['question'] ?? 'Question not available',
            'options': question['options'] ?? [],
            'correctAnswer': correctAnswerIndex,
            'studentAnswer': studentAnswerIndex,
            'explanation': question['explanation'] ?? 'No explanation available',
            'questionNumber': i + 1,
          });
        }
      }
    }
    
    return wrong;
  }

  Widget _buildWrongAnswerCard(Map<String, dynamic> wrongAnswer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Q${wrongAnswer['questionNumber']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  wrongAnswer['question'] ?? 'Question not available',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Options
          ...(wrongAnswer['options'] as List<dynamic>).asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isCorrect = index == wrongAnswer['correctAnswer'];
            final isStudentAnswer = index == wrongAnswer['studentAnswer'];
            
            Color optionColor = Colors.grey[300]!;
            IconData? optionIcon;
            
            if (isCorrect) {
              optionColor = Colors.green.withOpacity(0.2);
              optionIcon = Icons.check_circle;
            } else if (isStudentAnswer) {
              optionColor = Colors.red.withOpacity(0.2);
              optionIcon = Icons.cancel;
            }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: optionColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCorrect 
                      ? Colors.green 
                      : isStudentAnswer 
                          ? Colors.red 
                          : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  if (optionIcon != null) ...[
                    Icon(
                      optionIcon,
                      color: isCorrect ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCorrect || isStudentAnswer 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                        color: isCorrect 
                            ? Colors.green.shade800 
                            : isStudentAnswer 
                                ? Colors.red.shade800 
                                : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          const SizedBox(height: 16),
          
          // Explanation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Explanation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  wrongAnswer['explanation'] ?? 'No explanation available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 