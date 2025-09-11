class Quiz {
  final String title;
  final String subject;
  final int timeLimitMinutes;
  final List<Question> questions;

  Quiz({
    required this.title,
    required this.subject,
    required this.timeLimitMinutes,
    required this.questions,
  });

  // ADDED: Method to convert the Quiz object to a JSON-compatible Map
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subject': subject,
      'time_limit_seconds': timeLimitMinutes * 60, // Saving as seconds
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
  // ADDED: A constructor to create a Quiz object from a JSON map
  factory Quiz.fromJson(Map<String, dynamic> json) {
    var questionList = json['questions'] as List;
    List<Question> questions = questionList.map((q) => Question.fromJson(q)).toList();

    return Quiz(
      title: json['title'],
      subject: json['subject'],
      timeLimitMinutes: (json['time_limit_seconds'] / 60).round(),
      questions: questions,
    );
  }
}

class Question {
  String questionText;
  List<String> options;
  int correctAnswerIndex;

  Question({
    this.questionText = '',
    List<String>? options,
    this.correctAnswerIndex = 0,
  }) : options = options ?? ['', '', '', ''];

  // ADDED: Method to convert the Question object to a JSON-compatible Map
  Map<String, dynamic> toJson() {
    return {
      'question_text': questionText,
      'options': options,
      'correct_answer': options[correctAnswerIndex],
    };
  }

  // ADDED: A constructor to create a Question object from a JSON map
  factory Question.fromJson(Map<String, dynamic> json) {
    List<String> options = List<String>.from(json['options']);
    String correctAnswer = json['correct_answer'];
    int correctAnswerIndex = options.indexOf(correctAnswer);

    return Question(
      questionText: json['question_text'],
      options: options,
      correctAnswerIndex: correctAnswerIndex,
    );
  }
}