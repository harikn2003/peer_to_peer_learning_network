import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:peer_to_peer_learning_network/models/result_model.dart';
import 'package:collection/collection.dart'; // Add this to pubspec.yaml

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _isLoading = true;
  Map<String, List<QuizResult>> _resultsByQuiz = {};

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/quiz_results.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> allResultsJson = jsonDecode(content);
          final List<QuizResult> allResults = allResultsJson.map((json) => QuizResult.fromJson(json)).toList();

          // Group results by quiz title
          final grouped = groupBy(allResults, (QuizResult result) => result.quizTitle);
          setState(() {
            _resultsByQuiz = grouped;
          });
        }
      }
    } catch (e) {
      print("Error loading results: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text('Quiz Reports'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _resultsByQuiz.isEmpty
          ? const Center(child: Text('No quiz results have been received yet.'))
          : _buildResultsList(),
    );
  }

  Widget _buildResultsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _resultsByQuiz.entries.map((entry) {
        final quizTitle = entry.key;
        final results = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: const Icon(Icons.assessment_rounded, color: Colors.red),
            title: Text(quizTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${results.length} student(s) submitted'),
            children: results.map((result) {
              return ListTile(
                title: Text(result.studentName),
                subtitle: Text(result.studentClass),
                trailing: Text(
                  '${result.score}/${result.total}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}