import 'package:flutter/material.dart';
import 'package:peer_to_peer_learning_network/models/quiz_models.dart';

class QuizDetailsPage extends StatelessWidget {
  final Quiz quiz;

  const QuizDetailsPage({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(quiz.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildQuizMetadata(),
          const SizedBox(height: 24),
          ...quiz.questions.asMap().entries.map((entry) {
            int index = entry.key;
            Question question = entry.value;
            return _buildQuestionCard(question, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildQuizMetadata() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetadataItem(Icons.topic_outlined, 'Subject', quiz.subject),
            _buildMetadataItem(Icons.timer_outlined, 'Time Limit', '${quiz.timeLimitMinutes} mins'),
            _buildMetadataItem(Icons.question_answer_outlined, 'Questions', '${quiz.questions.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 28),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuestionCard(Question question, int questionNumber) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question $questionNumber', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(question.questionText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const Divider(height: 24),
            ...question.options.asMap().entries.map((entry) {
              int optionIndex = entry.key;
              String optionText = entry.value;
              bool isCorrect = optionIndex == question.correctAnswerIndex;

              return ListTile(
                leading: Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isCorrect ? Colors.green : Colors.grey.shade400,
                ),
                title: Text(
                  optionText,
                  style: TextStyle(
                    fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                    color: isCorrect ? Colors.green.shade800 : Colors.black87,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}