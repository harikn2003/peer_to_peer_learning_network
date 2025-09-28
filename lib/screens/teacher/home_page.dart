import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peer_to_peer_learning_network/screens/teacher/create_quiz_page.dart';
import 'package:peer_to_peer_learning_network/screens/teacher/content_management_page.dart';
import 'package:peer_to_peer_learning_network/screens/teacher/sharing_session_page.dart';
import 'package:peer_to_peer_learning_network/screens/teacher/reports_page.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  String _teacherName = 'Teacher';
  int _quizCount = 0; // State variable to hold the quiz count

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Loads both the teacher's name and the stats
  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();
    final quizzesDir = Directory('${directory.path}/quizzes');

    int count = 0;
    if (await quizzesDir.exists()) {
      // Count all .json files in all subject sub-folders
      count = quizzesDir.listSync(recursive: true).whereType<File>().length;
    }

    setState(() {
      _teacherName = prefs.getString('teacher_userName') ?? 'Teacher';
      _quizCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData, // Allows pull-to-refresh
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildActionsGrid(),
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
          'Welcome back, $_teacherName',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'What would you like to do today?',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // UPDATED: This widget is now functional
  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SharingSessionPage())),
            borderRadius: BorderRadius.circular(12),
            child: _buildStatCard('Start Session', 'Go', Icons.wifi_tethering_rounded, Colors.orange),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ContentManagementPage())),
            borderRadius: BorderRadius.circular(12),
            child: _buildStatCard('Saved Quizzes', _quizCount.toString(), Icons.quiz_outlined, Colors.lightBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(75))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color.shade800.withAlpha(200),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 20, color: color.shade700),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildActionCard(
          title: 'Create Quiz',
          icon: Icons.edit_note_rounded,
          color: Colors.amber.shade700,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateQuizPage()),
            ).then((_) => _loadInitialData()); // Refresh stats when returning
          },
        ),
        _buildActionCard(
          title: 'Manage Content',
          icon: Icons.folder_copy_rounded,
          color: Colors.green.shade600,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ContentManagementPage()),
            ).then((_) => _loadInitialData()); // Refresh stats when returning
          },
        ),
        _buildActionCard(
          title: 'View Reports',
          icon: Icons.bar_chart_rounded,
          color: Colors.red,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportsPage()),
            );
          },
        ),
        _buildActionCard(
          title: 'Start Sharing',
          icon: Icons.wifi_tethering_rounded,
          color: Colors.indigo,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SharingSessionPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withAlpha(25),
        highlightColor: color.withAlpha(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withAlpha(38),
                child: Icon(icon, size: 28, color: color),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to manage',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}