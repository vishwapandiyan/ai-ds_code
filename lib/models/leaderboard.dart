class LeaderboardEntry {
  final int id;
  final String studentId;
  final int levelId;
  final int score;
  final int timeTaken;
  final int? rankPosition;
  final DateTime completedAt;
  
  // Additional fields for display
  final String? studentName;
  final String? studentEmail;
  final String? levelTitle;
  final int? levelNumber;

  LeaderboardEntry({
    required this.id,
    required this.studentId,
    required this.levelId,
    required this.score,
    required this.timeTaken,
    this.rankPosition,
    required this.completedAt,
    this.studentName,
    this.studentEmail,
    this.levelTitle,
    this.levelNumber,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      id: map['id'] ?? 0,
      studentId: map['student_id'] ?? '',
      levelId: map['level_id'] ?? 0,
      score: map['score'] ?? 0,
      timeTaken: map['time_taken'] ?? 0,
      rankPosition: map['rank_position'],
      completedAt: map['completed_at'] != null 
          ? DateTime.parse(map['completed_at']) 
          : DateTime.now(),
      studentName: map['student_name'],
      studentEmail: map['student_email'],
      levelTitle: map['level_title'],
      levelNumber: map['level_number'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'level_id': levelId,
      'score': score,
      'time_taken': timeTaken,
      'rank_position': rankPosition,
      'completed_at': completedAt.toIso8601String(),
      'student_name': studentName,
      'student_email': studentEmail,
      'level_title': levelTitle,
      'level_number': levelNumber,
    };
  }

  String get formattedTime {
    final minutes = timeTaken ~/ 60;
    final seconds = timeTaken % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get scorePercentage {
    return '${score}%';
  }

  LeaderboardEntry copyWith({
    int? id,
    String? studentId,
    int? levelId,
    int? score,
    int? timeTaken,
    int? rankPosition,
    DateTime? completedAt,
    String? studentName,
    String? studentEmail,
    String? levelTitle,
    int? levelNumber,
  }) {
    return LeaderboardEntry(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      levelId: levelId ?? this.levelId,
      score: score ?? this.score,
      timeTaken: timeTaken ?? this.timeTaken,
      rankPosition: rankPosition ?? this.rankPosition,
      completedAt: completedAt ?? this.completedAt,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      levelTitle: levelTitle ?? this.levelTitle,
      levelNumber: levelNumber ?? this.levelNumber,
    );
  }
}
