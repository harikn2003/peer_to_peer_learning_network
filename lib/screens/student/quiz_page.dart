import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:peer_to_peer_learning_network/models/quiz_models.dart';
import 'package:peer_to_peer_learning_network/screens/student/quiz_results_page.dart'; // We will create this next

class QuizPage extends StatefulWidget {
  final File quizFile;
  final String teacherEndpointId;
  const QuizPage({super.key, required this.quizFile,required this.teacherEndpointId});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  Quiz? _quiz;
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  Timer? _timer;
  int _secondsRemaining = 0;

  // Map to store student's answers <questionIndex, selectedOptionIndex>
  final Map<int, int> _studentAnswers = {};
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    try {
      final jsonString = await widget.quizFile.readAsString();
      final jsonMap = jsonDecode(jsonString);
      final quizData = Quiz.fromJson(jsonMap);
      setState(() {
        _quiz = quizData;
        _secondsRemaining = quizData.timeLimitMinutes * 60;
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
      print('Error loading quiz: $e');
      // Handle error, maybe pop back
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _submitQuiz(); // Auto-submit when time runs out
      }
    });
  }

  void _submitQuiz() {
    _timer?.cancel();
    int score = 0;
    if (_quiz == null) return;

    for (int i = 0; i < _quiz!.questions.length; i++) {
      if (_studentAnswers.containsKey(i) &&
          _studentAnswers[i] == _quiz!.questions[i].correctAnswerIndex) {
        score++;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultsPage(
          score: score,
          totalQuestions: _quiz!.questions.length,
          quizTitle: _quiz!.title,
          teacherEndpointId: widget.teacherEndpointId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _quiz == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Quiz...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;

    return Scaffold(
      backgroundColor: Colors.amber.shade50,
      appBar: AppBar(
        title: Text(_quiz!.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 20, color: Colors.amber.shade800),
                const SizedBox(width: 4),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                ),
              ],
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1} of ${_quiz!.questions.length}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _quiz!.questions.length,
              backgroundColor: Colors.amber.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swiping
                itemCount: _quiz!.questions.length,
                itemBuilder: (context, index) {
                  final question = _quiz!.questions[index];
                  return _buildQuestionView(question, index);
                },
                onPageChanged: (index) {
                  setState(() {
                    _currentQuestionIndex = index;
                  });
                },
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionView(Question question, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.questionText,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
        ),
        const SizedBox(height: 30),
        ...question.options.asMap().entries.map((entry) {
          int optionIndex = entry.key;
          String optionText = entry.value;
          return _buildOption(optionText, optionIndex, index);
        }),
      ],
    );
  }

  Widget _buildOption(String text, int optionIndex, int questionIndex) {
    bool isSelected = _studentAnswers[questionIndex] == optionIndex;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.amber.shade700 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: RadioListTile<int>(
        value: optionIndex,
        groupValue: _studentAnswers[questionIndex],
        onChanged: (value) {
          setState(() {
            _studentAnswers[questionIndex] = value!;
          });
        },
        title: Text(
          text,
          style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
        activeColor: Colors.amber.shade700,
      ),
    );
  }

  Widget _buildNavigationButtons() {
    bool isLastQuestion = _currentQuestionIndex == _quiz!.questions.length - 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentQuestionIndex > 0)
          TextButton(
            onPressed: () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
              );
            },
            child: const Text('<< Previous'),
          ),
        const Spacer(),
        ElevatedButton(
          onPressed: () {
            if (isLastQuestion) {
              _submitQuiz();
            } else {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isLastQuestion ? Colors.green : Colors.amber.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(isLastQuestion ? 'Submit Quiz' : 'Next >>', style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}