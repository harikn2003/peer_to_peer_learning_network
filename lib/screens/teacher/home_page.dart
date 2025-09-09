import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  String _teacherName = 'Teacher';

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
  }

  Future<void> _loadTeacherName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _teacherName = prefs.getString('userName') ?? 'Teacher';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Teacher Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.grey.shade700),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings tapped!')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 24),
          _buildQuickStats(),
          const SizedBox(height: 24),
          Text(
           'Your Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          _buildActionsGrid(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $_teacherName!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'What would you like to achieve today?',
            style: TextStyle(fontSize: 17, color: Colors.indigo.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Active Sessions', '3', Icons.wifi_tethering_rounded, Colors.orange),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Pending Quizzes', '2', Icons.quiz_outlined, Colors.lightBlue),
        ),
      ],
    );
  }

  // Changed Color to MaterialColor for the `color` parameter
  Widget _buildStatCard(String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // Uses MaterialColor.withOpacity
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)) // Uses MaterialColor.withOpacity
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  // Accessing shades from MaterialColor is correct
                  color: color.shade800.withOpacity(0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              // Accessing shades from MaterialColor is correct
              Icon(icon, size: 20, color: color.shade700),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              // Accessing shades from MaterialColor is correct
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
          title: 'Start Sharing',
          icon: Icons.wifi_tethering_rounded,
          color: Colors.indigo, // This is a MaterialColor
          onTap: () { /* TODO: Implement navigation */ },
        ),
        _buildActionCard(
          title: 'Create Quiz',
          icon: Icons.edit_note_rounded,
          color: Colors.amber.shade700, // This is a Color (specific shade)
          onTap: () { /* TODO: Implement navigation */ },
        ),
        _buildActionCard(
          title: 'Upload Notes',
          icon: Icons.cloud_upload_outlined,
          color: Colors.green.shade600, // This is a Color (specific shade)
          onTap: () { /* TODO: Implement navigation */ },
        ),
        _buildActionCard(
          title: 'View Reports',
          icon: Icons.assessment_outlined,
          color: Colors.red.shade600, // This is a Color (specific shade)
          onTap: () { /* TODO: Implement navigation */ },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color, // Parameter remains Color, as it can be MaterialColor or a specific shade
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        onTap: () {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title tapped! Implement navigation.')),
          );
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, size: 28, color: color),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  // Corrected: Use the passed color directly.
                  // If 'color' is MaterialColor, it defaults to its primary shade (e.g. shade500).
                  // If 'color' is a specific shade (Color), it uses that shade.
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
