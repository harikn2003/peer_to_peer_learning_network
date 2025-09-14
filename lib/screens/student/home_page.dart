import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peer_to_peer_learning_network/screens/student/quiz_page.dart';
import 'package:peer_to_peer_learning_network/screens/student/receiving_session_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  String _studentName = 'Student';

  // Demo data - replace with your actual data fetching logic
  final List<Map<String, dynamic>> _allFiles = [
    {'title': 'Water Cycle Quiz', 'subtitle': 'Science', 'icon': Icons.quiz_rounded, 'color': Colors.amber, 'isQuiz': true},
    {'title': 'Chapter 5 Notes', 'subtitle': 'History', 'icon': Icons.menu_book_rounded, 'color': Colors.red, 'isQuiz': false},
    {'title': 'Photosynthesis Video', 'subtitle': 'Biology', 'icon': Icons.play_circle_filled_rounded, 'color': Colors.blue, 'isQuiz': false},
    {'title': 'Algebra Practice', 'subtitle': 'Mathematics', 'icon': Icons.calculate_rounded, 'color': Colors.purple, 'isQuiz': true},
  ];

  @override
  void initState() {
    super.initState();
    _loadStudentName();
  }

  Future<void> _loadStudentName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentName = prefs.getString('student_userName') ?? 'Student';
    });
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
      body: ListView(
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
          _buildSectionHeader('All Quizzes'),
          const SizedBox(height: 12),
          _buildContentList(isQuiz: true),
          const SizedBox(height: 24),
          _buildSectionHeader('All Notes'),
          const SizedBox(height: 12),
          _buildContentList(isQuiz: false),
        ],
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
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ready to learn something new today?',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildReceiveContentCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReceivingSessionPage()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.wifi_tethering_rounded, color: Colors.white, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Receive Content',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap here to connect to your teacher and download new files.',
                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    ),
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
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildRecentFilesList() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _allFiles.length,
        itemBuilder: (context, index) {
          final file = _allFiles[index];
          return _buildRecentFileCard(
            context,
            file['title'],
            file['icon'],
            file['color'],
            file['isQuiz'],
          );
        },
      ),
    );
  }

  Widget _buildRecentFileCard(BuildContext context, String title, IconData icon, Color color, bool isQuiz) {
    return SizedBox(
      width: 130,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            if (isQuiz) Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizPage()));
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis,),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentList({required bool isQuiz}) {
    final filteredFiles = _allFiles.where((file) => file['isQuiz'] == isQuiz).toList();

    if (filteredFiles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text("No items in this category yet."),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredFiles.length,
      itemBuilder: (context, index) {
        final file = filteredFiles[index];
        return _buildFileTile(
          context,
          file['title'],
          file['subtitle'],
          file['icon'],
          file['color'],
          file['isQuiz'],
        );
      },
    );
  }

  Widget _buildFileTile(BuildContext context, String title, String subtitle, IconData icon, Color color, bool isQuiz) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(25),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          if (isQuiz) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QuizPage()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening $title...')),
            );
          }
        },
      ),
    );
  }
}