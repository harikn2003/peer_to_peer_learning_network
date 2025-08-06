import 'package:flutter/material.dart';
import 'package:peer_to_peer_learning_network/screens/student/home_page.dart' as student;
import 'package:peer_to_peer_learning_network/screens/teacher/pin_login_page.dart' as teacher;

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cast_for_education, size: 80, color: Colors.indigo),
            const SizedBox(height: 20),
            const Text(
              'Welcome to the Learning Hub',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please select your role to continue',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 50),
            // Teacher Role Card
            _buildRoleCard(
              context: context,
              icon: Icons.school,
              title: 'I am a Teacher',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const teacher.PinLoginPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            // Student Role Card
            _buildRoleCard(
              context: context,
              icon: Icons.person,
              title: 'I am a Student',
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const student.StudentHomePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.75,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}