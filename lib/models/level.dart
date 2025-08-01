class Level {
  final int id;
  final int levelNumber;
  final String title;
  final String description;
  final DateTime createdAt;
  final List<MCQ>? mcqs;

  Level({
    required this.id,
    required this.levelNumber,
    required this.title,
    required this.description,
    required this.createdAt,
    this.mcqs,
  });

  factory Level.fromMap(Map<String, dynamic> map) {
    return Level(
      id: map['id'] ?? 0,
      levelNumber: map['level_number'] ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      mcqs: map['mcqs'] != null 
          ? List<MCQ>.from(map['mcqs'].map((x) => MCQ.fromMap(x)))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'level_number': levelNumber,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'mcqs': mcqs?.map((x) => x.toMap()).toList(),
    };
  }

  Level copyWith({
    int? id,
    int? levelNumber,
    String? title,
    String? description,
    DateTime? createdAt,
    List<MCQ>? mcqs,
  }) {
    return Level(
      id: id ?? this.id,
      levelNumber: levelNumber ?? this.levelNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      mcqs: mcqs ?? this.mcqs,
    );
  }
}

class MCQ {
  final int id;
  final int levelId;
  final int questionNumber;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final DateTime createdAt;

  MCQ({
    required this.id,
    required this.levelId,
    required this.questionNumber,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.createdAt,
  });

  factory MCQ.fromMap(Map<String, dynamic> map) {
    return MCQ(
      id: map['id'] ?? 0,
      levelId: map['level_id'] ?? 0,
      questionNumber: map['question_number'] ?? 0,
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correct_answer'] ?? 0,
      explanation: map['explanation'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'level_id': levelId,
      'question_number': questionNumber,
      'question': question,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MCQ copyWith({
    int? id,
    int? levelId,
    int? questionNumber,
    String? question,
    List<String>? options,
    int? correctAnswer,
    String? explanation,
    DateTime? createdAt,
  }) {
    return MCQ(
      id: id ?? this.id,
      levelId: levelId ?? this.levelId,
      questionNumber: questionNumber ?? this.questionNumber,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 