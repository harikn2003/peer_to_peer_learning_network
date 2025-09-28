import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizResultsPage extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String quizTitle;
  final String teacherEndpointId;

  const QuizResultsPage({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.quizTitle,
    required this.teacherEndpointId,
  });

  @override
  State<QuizResultsPage> createState() => _QuizResultsPageState();
}

class _QuizResultsPageState extends State<QuizResultsPage> {
  @override
  void initState() {
    super.initState();
    _sendResultsToTeacher();
  }

  Future<void> _sendResultsToTeacher() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Load student's name, class, and division
      final studentName = prefs.getString('student_userName') ?? 'Student';
      final studentClass = prefs.getString('student_class') ?? 'Unknown';
      final studentDivision = prefs.getString('student_division') ?? '';

      // Create a result payload with the new info
      Map<String, dynamic> resultPayload = {
        'type': 'quiz_result',
        'studentName': studentName,
        'studentClass': '$studentClass - $studentDivision',
        'quizTitle': widget.quizTitle,
        'score': widget.score,
        'total': widget.totalQuestions,
      };

      // Convert to bytes and send
      final resultBytes = Uint8List.fromList(jsonEncode(resultPayload).codeUnits);
      await Nearby().sendBytesPayload(widget.teacherEndpointId, resultBytes);

      print('Results sent to teacher!');
    } catch (e) {
      print('Error sending results: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Quiz Results'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Quiz Completed!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Score:',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
            Text(
              '${widget.score} / ${widget.totalQuestions}',
              style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your results have been sent to the teacher.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: const Text('Finish'),
            ),
          ],
        ),
      ),
    );
  }
}