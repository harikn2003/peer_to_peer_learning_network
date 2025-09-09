import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peer_to_peer_learning_network/screens/student/quiz_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  String _studentName = 'Student';

  @override
  void initState() {
    super.initState();
    _loadStudentName();
  }

  Future<void> _loadStudentName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentName = prefs.getString('userName') ?? 'Student';
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.green.shade50,
        appBar: AppBar(
          title: Text('Hi, $_studentName!', style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey.shade800,
          elevation: 1,
          bottom: TabBar(
            indicatorColor: Colors.green.shade700, // Darker green indicator
            indicatorWeight: 3.0, // Slightly thicker indicator
            labelColor: Colors.green.shade800, // Darker label color
            unselectedLabelColor: Colors.grey.shade500,
            labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), // Bolder labels
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Quizzes'),
              Tab(text: 'Notes'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildReceiveContentCard(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFilesList(showAll: true),
                  _buildFilesList(isQuiz: true),
                  _buildFilesList(isQuiz: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiveContentCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 12.0), // Adjusted padding
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Searching for teacher...')),
          );
        },
        borderRadius: BorderRadius.circular(16), // For splash effect to match container
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center content
            children: const [
              Icon(Icons.wifi_tethering_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Find & Receive Content',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilesList({bool showAll = false, bool isQuiz = false}) {
    // Demo data - replace with your actual data fetching logic
    final List<Map<String, dynamic>> allFiles = [
      {'title': 'Water Cycle Quiz', 'subtitle': 'Science - Biology', 'icon': Icons.quiz_rounded, 'color': Colors.amber.shade700, 'isQuiz': true},
      {'title': 'Chapter 5 Notes: Ancient Civilizations', 'subtitle': 'History - Grade 10', 'icon': Icons.menu_book_rounded, 'color': Colors.red.shade600, 'isQuiz': false},
      {'title': 'Photosynthesis Explained (Video)', 'subtitle': 'Biology - Visual Learning', 'icon': Icons.play_circle_filled_rounded, 'color': Colors.blue.shade600, 'isQuiz': false},
      {'title': 'Algebra Practice Problems', 'subtitle': 'Mathematics - Unit 2', 'icon': Icons.calculate_rounded, 'color': Colors.purple.shade600, 'isQuiz': true},
       {'title': 'Poetry Analysis Guide', 'subtitle': 'Literature - Tips & Tricks', 'icon': Icons.description_rounded, 'color': Colors.teal.shade600, 'isQuiz': false}, // Changed icon here
    ];

    List<Map<String, dynamic>> filteredFiles = allFiles;
    if (!showAll) {
      filteredFiles = allFiles.where((file) => file['isQuiz'] == isQuiz).toList();
    }

    if (filteredFiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_off_outlined, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                "No files found here yet!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            ],
          ),
        )
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0), // Adjusted padding
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
      elevation: 2.5, // Subtle elevation
      margin: const EdgeInsets.only(bottom: 16.0), // Increased bottom margin
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // More rounded corners
      child: InkWell(
        onTap: () {
          if (isQuiz) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QuizPage()), // Assuming QuizPage exists
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening $title...')),
            );
          }
        },
        borderRadius: BorderRadius.circular(16), // Match card's shape for splash effect
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Consistent padding
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12), // Slightly more distinct background for icon
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28), // Adjusted icon size
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5), // Slightly larger title
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5), // Adjusted spacing
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600), // Slightly smaller, clear subtitle
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8), // Provide some space before the arrow
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400), // Subtler arrow
            ],
          ),
        ),
      ),
    );
  }
}
