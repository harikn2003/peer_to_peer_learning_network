import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:peer_to_peer_learning_network/models/quiz_models.dart';
import 'package:peer_to_peer_learning_network/screens/teacher/quiz_details_page.dart';
import 'package:peer_to_peer_learning_network/screens/teacher/create_quiz_page.dart'; // Add this import

class ContentManagementPage extends StatefulWidget {
  const ContentManagementPage({super.key});

  @override
  State<ContentManagementPage> createState() => _ContentManagementPageState();
}

class _ContentManagementPageState extends State<ContentManagementPage> {
  bool _isLoading = true;
  List<File> _quizFiles = [];

  @override
  void initState() {
    super.initState();
    _loadSavedQuizzes();
  }

  Future<void> _loadSavedQuizzes() async {
    // Make sure we show the loading indicator when refreshing
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final quizzesDir = Directory('${directory.path}/quizzes');

      if (await quizzesDir.exists()) {
        final files = quizzesDir.listSync();
        setState(() {
          _quizFiles = files.whereType<File>().where((file) => file.path.endsWith('.json')).toList();
        });
      } else {
        // If the directory doesn't even exist, the list is empty
        setState(() {
          _quizFiles = [];
        });
      }
    } catch (e) {
      print('Error loading quizzes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToQuizDetails(File quizFile) async {
    // ... this function remains the same
    try {
      final jsonString = await quizFile.readAsString();
      final jsonMap = jsonDecode(jsonString);
      final quiz = Quiz.fromJson(jsonMap);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QuizDetailsPage(quiz: quiz)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading quiz file: $e')),
      );
    }
  }

  String _formatFileName(String path) {
    return path.split('/').last.replaceAll('-', ' ').replaceAll('.json', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text('My Content'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 1,
      ),
      // ADDED: FloatingActionButton to create a new quiz
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigate to CreateQuizPage and wait for a result
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateQuizPage()),
          );

          // If a quiz was successfully saved, refresh the list
          if (result == true) {
            _loadSavedQuizzes();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Quiz'),
        backgroundColor: Colors.amber.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizFiles.isEmpty
          ? _buildEmptyState()
          : _buildContentList(),
    );
  }

  // ... _buildEmptyState and _buildContentList methods remain the same ...
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Quizzes Found',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the "Create Quiz" button to get started.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // Add padding for FAB
      itemCount: _quizFiles.length,
      itemBuilder: (context, index) {
        final file = _quizFiles[index];
        final quizTitle = _formatFileName(file.path);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            leading: const CircleAvatar(
              backgroundColor: Colors.amber,
              child: Icon(Icons.quiz_rounded, color: Colors.white),
            ),
            title: Text(
              quizTitle.isNotEmpty ? '${quizTitle[0].toUpperCase()}${quizTitle.substring(1)}' : '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Quiz File'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              _navigateToQuizDetails(file);
            },
          ),
        );
      },
    );
  }
}