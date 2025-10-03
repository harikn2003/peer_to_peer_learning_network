import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:peer_to_peer_learning_network/models/quiz_models.dart';
import 'package:peer_to_peer_learning_network/screens/teacher/quiz_details_page.dart';
import 'package:peer_to_peer_learning_network/screens/teacher/create_quiz_page.dart';

class ContentManagementPage extends StatefulWidget {
  final bool isSelectionMode;
  const ContentManagementPage({super.key, this.isSelectionMode = false});

  @override
  State<ContentManagementPage> createState() => _ContentManagementPageState();
}

class _ContentManagementPageState extends State<ContentManagementPage> {
  bool _isLoading = true;
  List<File> _quizFiles = [];
  List<File> _noteFiles = [];
  final List<File> _selectedFiles = [];

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
        final files = quizzesDir.listSync(recursive: true).whereType<File>().toList();
        setState(() {
          _quizFiles = files;
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
        final files = notesDir.listSync(recursive: true).whereType<File>().toList();
        setState(() {
          _noteFiles = files;
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

  Future<void> _deleteFile(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to permanently delete "${path.basename(file.path)}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await file.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${path.basename(file.path)}" was deleted.')),
          );
        }
        // Refresh the content lists to reflect the deletion
        await _loadAllContent();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting file: $e')),
          );
        }
      }
    }
  }

  Future<void> _uploadNote() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'mp4', 'txt', 'jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final sourceFile = File(result.files.single.path!);
      final fileName = path.basename(sourceFile.path);
      final directory = await getApplicationDocumentsDirectory();
      final notesDir = Directory('${directory.path}/notes');
      if (!await notesDir.exists()) {
        await notesDir.create(recursive: true);
      }
      final destinationPath = '${notesDir.path}/$fileName';

      await sourceFile.copy(destinationPath);

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

  Future<void> _onFileTap(File file) async {
    if (widget.isSelectionMode) {
      setState(() {
        if (_selectedFiles.contains(file)) {
          _selectedFiles.remove(file);
        } else {
          _selectedFiles.add(file);
        }
      });
    } else {
      if (file.path.endsWith('.json')) {
        _navigateToQuizDetails(file);
      } else {
        await OpenFile.open(file.path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.indigo.shade50,
        appBar: AppBar(
          title: Text(widget.isSelectionMode ? 'Select Content' : 'My Content'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey.shade800,
          elevation: 1,
          bottom: const TabBar(
            indicatorColor: Colors.indigo,
            labelColor: Colors.indigo,
            tabs: [
              Tab(text: 'Quizzes'),
              Tab(text: 'Notes'),
            ],
          ),
          actions: [
            if (widget.isSelectionMode)
              IconButton(
                icon: const Icon(Icons.check_rounded),
                onPressed: () {
                  Navigator.pop(context, _selectedFiles);
                },
              ),
          ],
        ),
        floatingActionButton: widget.isSelectionMode
            ? null
            : FloatingActionButton(
          onPressed: _showAddContentDialog,
          backgroundColor: Colors.indigo,
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
        final isSelected = _selectedFiles.contains(file);
        return Card(
          color: isSelected ? Colors.indigo.shade100 : Colors.white,
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
              file.path.split('/').last.replaceAll('-', ' ').replaceAll('.json', ''),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(file.parent.path.split('/').last),
            // UPDATED: Trailing widget is now conditional
            trailing: widget.isSelectionMode
                ? Icon(
              isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: Colors.indigo,
            )
                : IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
              onPressed: () => _deleteFile(file),
              tooltip: 'Delete Quiz',
            ),
            onTap: () => _onFileTap(file),
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
        final noteTitle = path.basename(file.path);
        final isSelected = _selectedFiles.contains(file);

        IconData getIconForFile(String fileName) {
          final ext = fileName.toLowerCase();
          if (ext.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
          if (ext.endsWith('.mp4')) return Icons.video_library_rounded;
          if (ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png')) return Icons.image_rounded;
          return Icons.note_alt_rounded; // Default icon
        }

        Color getColorForFile(String fileName) {
          final ext = fileName.toLowerCase();
          if (ext.endsWith('.pdf')) return Colors.red;
          if (ext.endsWith('.mp4')) return Colors.orange;
          if (ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png')) return Colors.purple;
          return Colors.blue; // Default color
        }

        return Card(
          color: isSelected ? Colors.indigo.shade100 : Colors.white,
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
            subtitle: Text(file.parent.path.split('/').last),
            trailing: widget.isSelectionMode
                ? Icon(
              isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: Colors.indigo,
            )
                : IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
              onPressed: () => _deleteFile(file),
              tooltip: 'Delete Note',
            ),
            onTap: () => _onFileTap(file),
          ),
        );
      },
    );
  }
}