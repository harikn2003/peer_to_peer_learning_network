class QuizResult {
  final String studentName;
  final String studentClass;
  final String quizTitle;
  final int score;
  final int total;

  QuizResult({
    required this.studentName,
    required this.studentClass,
    required this.quizTitle,
    required this.score,
    required this.total,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      studentName: json['studentName'] ?? 'Unknown Student',
      studentClass: json['studentClass'] ?? 'Unknown Class',
      quizTitle: json['quizTitle'] ?? 'Untitled Quiz',
      score: json['score'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}