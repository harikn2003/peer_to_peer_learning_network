import 'dart:convert'; // For jsonEncode
import 'dart:io'; // For File operations
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // To find file paths
import 'package:peer_to_peer_learning_network/models/quiz_models.dart';

class CreateQuizPage extends StatefulWidget {
  const CreateQuizPage({super.key});

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _timeController = TextEditingController();

  final List<Question> _questions = [Question()];

  void _addQuestion() {
    setState(() {
      _questions.add(Question());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  // REPLACED: This function now handles the entire file saving process.
  Future<void> _saveQuiz() async {
    if (_formKey.currentState!.validate()) {
      try {
        final quiz = Quiz(
          title: _titleController.text,
          subject: _subjectController.text,
          timeLimitMinutes: int.tryParse(_timeController.text) ?? 0,
          questions: _questions,
        );

        // 1. Convert the Quiz object to a JSON string
        final jsonString = jsonEncode(quiz.toJson());

        // 2. Get the directory to store files
        final directory = await getApplicationDocumentsDirectory();
        final quizzesDir = Directory('${directory.path}/quizzes');
        if (!await quizzesDir.exists()) {
          await quizzesDir.create(recursive: true); // Create folder if it doesn't exist
        }

        // 3. Create a unique filename (e.g., "water-cycle-quiz.json")
        final fileName = '${quiz.title.toLowerCase().replaceAll(' ', '-')}.json';
        final file = File('${quizzesDir.path}/$fileName');

        // 4. Write the JSON string to the file
        await file.writeAsString(jsonString);

        // 5. Show success message and navigate back
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quiz "${quiz.title}" saved successfully!')),
        );
        Navigator.pop(context,true);

      } catch (e) {
        // Handle any errors during file saving
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving quiz: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  // The build method and all its helper widgets remain exactly the same.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Create a New Quiz'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _saveQuiz,
            tooltip: 'Save Quiz',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildQuizMetadata(),
            const SizedBox(height: 24),
            _buildQuestionsList(),
            const SizedBox(height: 16),
            _buildAddQuestionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizMetadata() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quiz Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Quiz Title', border: OutlineInputBorder()),
              validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Please enter a subject' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _timeController,
                    decoration: const InputDecoration(labelText: 'Time (Minutes)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Set time' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        return _buildQuestionCard(index);
      },
    );
  }

  Widget _buildQuestionCard(int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Question ${index + 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                if (_questions.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                    onPressed: () => _removeQuestion(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _questions[index].questionText,
              onChanged: (value) => _questions[index].questionText = value,
              decoration: const InputDecoration(labelText: 'Question Text', border: OutlineInputBorder()),
              validator: (value) => value!.isEmpty ? 'Enter a question' : null,
            ),
            const SizedBox(height: 16),
            const Text('Options (select the correct one):', style: TextStyle(fontWeight: FontWeight.w500)),
            for (int i = 0; i < 4; i++)
              RadioListTile(
                title: TextFormField(
                  initialValue: _questions[index].options[i],
                  onChanged: (value) => _questions[index].options[i] = value,
                  decoration: InputDecoration(hintText: 'Option ${i + 1}'),
                  validator: (value) => value!.isEmpty ? 'Option cannot be empty' : null,
                ),
                value: i,
                groupValue: _questions[index].correctAnswerIndex,
                onChanged: (value) {
                  setState(() {
                    _questions[index].correctAnswerIndex = value as int;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddQuestionButton() {
    return ElevatedButton.icon(
      onPressed: _addQuestion,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Another Question'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}