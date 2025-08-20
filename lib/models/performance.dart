class Performance {
  final int id;
  final String studentId;
  final int levelId;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int timeTaken; // in seconds
  final List<Map<String, dynamic>> answers;
  final DateTime completedAt;
  final Map<String, dynamic>? level;

  Performance({
    required this.id,
    required this.studentId,
    required this.levelId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeTaken,
    required this.answers,
    required this.completedAt,
    this.level,
  });

  factory Performance.fromMap(Map<String, dynamic> map) {
    return Performance(
      id: map['id'] ?? 0,
      studentId: map['student_id'] ?? '',
      levelId: map['level_id'] ?? 0,
      score: map['score'] ?? 0,
      totalQuestions: map['total_questions'] ?? 0,
      correctAnswers: map['correct_answers'] ?? 0,
      timeTaken: map['time_taken'] ?? 0,
      answers: List<Map<String, dynamic>>.from(map['answers'] ?? []),
      completedAt: map['completed_at'] != null 
          ? DateTime.parse(map['completed_at']) 
          : DateTime.now(),
      level: map['levels'] != null ? Map<String, dynamic>.from(map['levels']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'level_id': levelId,
      'score': score,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'time_taken': timeTaken,
      'answers': answers,
      'completed_at': completedAt.toIso8601String(),
      'levels': level,
    };
  }

  Performance copyWith({
    int? id,
    String? studentId,
    int? levelId,
    int? score,
    int? totalQuestions,
    int? correctAnswers,
    int? timeTaken,
    List<Map<String, dynamic>>? answers,
    DateTime? completedAt,
    Map<String, dynamic>? level,
  }) {
    return Performance(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      levelId: levelId ?? this.levelId,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      timeTaken: timeTaken ?? this.timeTaken,
      answers: answers ?? this.answers,
      completedAt: completedAt ?? this.completedAt,
      level: level ?? this.level,
    );
  }

  double get percentage => totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;
  bool get passed => percentage >= 70;
  String get timeTakenFormatted {
    final minutes = timeTaken ~/ 60;
    final seconds = timeTaken % 60;
    return '${minutes}m ${seconds}s';
  }
} 