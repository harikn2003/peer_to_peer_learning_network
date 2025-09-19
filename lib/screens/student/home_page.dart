import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peer_to_peer_learning_network/screens/student/quiz_page.dart';
import 'package:peer_to_peer_learning_network/screens/student/receiving_session_page.dart';
import 'package:peer_to_peer_learning_network/screens/student/pdf_viewer_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  String _studentName = 'Student';
  bool _isLoading = true;

  Map<String, List<File>> _quizzesBySubject = {};
  Map<String, List<File>> _notesBySubject = {};
  List<File> _allFiles = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await _loadStudentName();
    await _loadContent();
    setState(() => _isLoading = false);
  }

  Future<void> _loadStudentName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentName = prefs.getString('student_userName') ?? 'Student';
    });
  }

  Future<void> _loadContent() async {
    final directory = await getApplicationDocumentsDirectory();
    final quizzesDir = Directory('${directory.path}/quizzes');
    final notesDir = Directory('${directory.path}/notes');

    Map<String, List<File>> quizMap = {};
    if (await quizzesDir.exists()) {
      final subjectDirs = quizzesDir.listSync().whereType<Directory>();
      for (var dir in subjectDirs) {
        final subjectName = dir.path.split('/').last;
        final files = dir.listSync().whereType<File>().toList();
        if (files.isNotEmpty) quizMap[subjectName] = files;
      }
    }

    Map<String, List<File>> noteMap = {};
    if (await notesDir.exists()) {
      final subjectDirs = notesDir.listSync().whereType<Directory>();
      for (var dir in subjectDirs) {
        final subjectName = dir.path.split('/').last;
        final files = dir.listSync().whereType<File>().toList();
        if (files.isNotEmpty) noteMap[subjectName] = files;
      }
    }

    setState(() {
      _quizzesBySubject = quizMap;
      _notesBySubject = noteMap;
      _allFiles = [...quizMap.values.expand((files) => files), ...noteMap.values.expand((files) => files)];
    });
  }

  void _onFileTapped(BuildContext context, File file) {
    final fileName = file.path.split('/').last;
    final isQuiz = fileName.toLowerCase().endsWith('.json');
    final isPdf = fileName.toLowerCase().endsWith('.pdf');

    if (isQuiz) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QuizPage()),
      );
    } else if (isPdf) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PdfViewerPage(file: file)),
      );
    } else {
      // Placeholder for other file types like videos
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening $fileName...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('My Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadInitialData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            _buildReceiveContentCard(),
            const SizedBox(height: 24),
            _buildSectionHeader('Recently Received'),
            const SizedBox(height: 12),
            _buildRecentFilesList(),
            const SizedBox(height: 24),
            _buildSectionHeader('Quizzes by Subject'),
            const SizedBox(height: 12),
            _buildSubjectSection(dataMap: _quizzesBySubject, isQuiz: true),
            const SizedBox(height: 24),
            _buildSectionHeader('Notes by Subject'),
            const SizedBox(height: 12),
            _buildSubjectSection(dataMap: _notesBySubject, isQuiz: false),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi, $_studentName!',
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800),
        ),
        const SizedBox(height: 4),
        Text('Ready to learn something new today?',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildReceiveContentCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ReceivingSessionPage()));
          _loadContent(); // Refresh content when returning
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
          child: Row(
            children: [
              const Icon(Icons.wifi_tethering_rounded,
                  color: Colors.white, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Receive Content',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Tap here to connect and download new files.',
                        style: TextStyle(color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title,
        style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700));
  }

  Widget _buildRecentFilesList() {
    if (_allFiles.isEmpty) {
      return const SizedBox(
          height: 140, child: Center(child: Text('No recent files.')));
    }
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _allFiles.length > 5 ? 5 : _allFiles.length,
        itemBuilder: (context, index) {
          final file = _allFiles[index];
          return _buildRecentFileCard(context, file);
        },
      ),
    );
  }

  Widget _buildRecentFileCard(BuildContext context, File file) {
    final isQuiz = file.path.endsWith('.json');
    final title = file.path.split('/').last.replaceAll('.json', '').replaceAll('-', ' ');
    final icon = isQuiz ? Icons.quiz_rounded : Icons.menu_book_rounded;
    final color = isQuiz ? Colors.amber : Colors.blue;

    return SizedBox(
      width: 130,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _onFileTapped(context, file), // UPDATED
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectSection(
      {required Map<String, List<File>> dataMap, required bool isQuiz}) {
    if (dataMap.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text("No ${isQuiz ? 'quizzes' : 'notes'} received yet.",
            style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dataMap.entries.map((entry) {
        final subject = entry.key;
        final files = entry.value;
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: Icon(
                isQuiz ? Icons.quiz_rounded : Icons.menu_book_rounded,
                color: isQuiz ? Colors.amber : Colors.blue),
            title: Text(subject,
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text('${files.length} item(s)'),
            children:
            files.map((file) => _buildFileTile(context, file, isQuiz)).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFileTile(BuildContext context, File file, bool isQuiz) {
    final fileName = file.path.split('/').last.replaceAll('.json', '').replaceAll('-', ' ');
    final subject = file.parent.path.split('/').last;

    // Helper to get icon/color based on file extension for notes
    IconData getNoteIcon(File noteFile) {
      if (noteFile.path.toLowerCase().endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
      if (noteFile.path.toLowerCase().endsWith('.mp4')) return Icons.video_library_rounded;
      return Icons.note_alt_rounded;
    }
    Color getNoteColor(File noteFile) {
      if (noteFile.path.toLowerCase().endsWith('.pdf')) return Colors.red;
      if (noteFile.path.toLowerCase().endsWith('.mp4')) return Colors.orange;
      return Colors.blue;
    }

    final icon = isQuiz ? Icons.quiz_rounded : getNoteIcon(file);
    final color = isQuiz ? Colors.amber : getNoteColor(file);

    return ListTile(
      leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 28)),
      title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: isQuiz ? Text(subject) : null,
      trailing:
      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () => _onFileTapped(context, file), // UPDATED
    );
  }
}