import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path; // Import the path package
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart'; // Add this import
import 'package:peer_to_peer_learning_network/models/quiz_models.dart';
import 'package:peer_to_peer_learning_network/screens/teacher/quiz_details_page.dart';
import 'package:peer_to_peer_learning_network/screens/teacher/create_quiz_page.dart';

class ContentManagementPage extends StatefulWidget {
  const ContentManagementPage({super.key});

  @override
  State<ContentManagementPage> createState() => _ContentManagementPageState();
}

class _ContentManagementPageState extends State<ContentManagementPage> {
  bool _isLoading = true;
  List<File> _quizFiles = [];
  List<File> _noteFiles = [];

  @override
  void initState() {
    super.initState();
    _loadAllContent();
  }

  Future<void> _loadAllContent() async {
    await _loadSavedQuizzes();
    await _loadSavedNotes();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSavedQuizzes() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final quizzesDir = Directory('${directory.path}/quizzes');
      if (await quizzesDir.exists()) {
        final files = quizzesDir.listSync();
        setState(() {
          _quizFiles = files
              .whereType<File>()
              .where((file) => file.path.endsWith('.json'))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading quizzes: $e');
    }
  }

  Future<void> _loadSavedNotes() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final notesDir = Directory('${directory.path}/notes');
      if (await notesDir.exists()) {
        final files = notesDir.listSync();
        setState(() {
          _noteFiles = files.whereType<File>().toList();
        });
      }
    } catch (e) {
      print('Error loading notes: $e');
    }
  }

  Future<void> _navigateToQuizDetails(File quizFile) async {
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

  // ADDED: Logic for picking and saving a note file
  Future<void> _uploadNote() async {
    try {
      // 1. Pick a file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'mp4', 'txt'],
      );

      if (result == null || result.files.single.path == null) {
        // User canceled the picker
        return;
      }

      // 2. Get the file path and create a destination path
      final sourceFile = File(result.files.single.path!);
      final fileName = path.basename(sourceFile.path); // Get the original filename

      final directory = await getApplicationDocumentsDirectory();
      final notesDir = Directory('${directory.path}/notes');
      if (!await notesDir.exists()) {
        await notesDir.create(recursive: true);
      }
      final destinationPath = '${notesDir.path}/$fileName';

      // 3. Copy the file to the app's directory
      await sourceFile.copy(destinationPath);

      // 4. Refresh the list of notes and show a success message
      await _loadSavedNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note "$fileName" uploaded successfully!')),
        );
      }
    } catch (e) {
      print('Error uploading note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading note: $e')),
      );
    }
  }

  void _showAddContentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Add New Content'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateQuizPage()),
                );
                if (result == true) {
                  _loadSavedQuizzes();
                }
              },
              child: const ListTile(
                leading: Icon(Icons.quiz_rounded, color: Colors.amber),
                title: Text('Create a Quiz'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                // CHANGED: Call the new upload function
                _uploadNote();
              },
              child: const ListTile(
                leading: Icon(Icons.note_alt_rounded, color: Colors.blue),
                title: Text('Upload a Note'),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatFileName(String path) {
    return path.split('/').last.replaceAll('-', ' ').replaceAll('.json', '');
  }

  @override
  Widget build(BuildContext context) {
    // ... UI Code remains the same ...
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.indigo.shade50,
        appBar: AppBar(
          title: const Text('My Content'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey.shade800,
          elevation: 1,
          bottom: const TabBar(
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            tabs: [
              Tab(text: 'Quizzes'),
              Tab(text: 'Notes'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddContentDialog,
          backgroundColor: Colors.deepOrange,
          child: const Icon(Icons.add),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            _quizFiles.isEmpty ? _buildEmptyState('Quizzes') : _buildQuizList(),
            _noteFiles.isEmpty ? _buildEmptyState('Notes') : _buildNoteList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String contentType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No $contentType Found',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the "+" button to add new content.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
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

  Widget _buildNoteList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
      itemCount: _noteFiles.length,
      itemBuilder: (context, index) {
        final file = _noteFiles[index];
        final noteTitle = path.basename(file.path); // Use path.basename for a clean name

        // Helper to get an appropriate icon and color based on file type
        IconData getIconForFile(String fileName) {
          if (fileName.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
          if (fileName.endsWith('.mp4')) return Icons.video_library_rounded;
          return Icons.note_alt_rounded;
        }

        Color getColorForFile(String fileName) {
          if (fileName.endsWith('.pdf')) return Colors.red;
          if (fileName.endsWith('.mp4')) return Colors.orange;
          return Colors.blue;
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            leading: CircleAvatar(
              backgroundColor: getColorForFile(noteTitle),
              child: Icon(getIconForFile(noteTitle), color: Colors.white),
            ),
            title: Text(
              noteTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${(file.lengthSync() / 1024).toStringAsFixed(2)} KB'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              // Placeholder for viewing a note
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note viewing feature coming soon!')),
              );
            },
          ),
        );
      },
    );
  }
}