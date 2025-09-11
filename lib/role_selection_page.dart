import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peer_to_peer_learning_network/splash_page.dart';
import 'package:peer_to_peer_learning_network/screens/common/login_page.dart';
import 'package:peer_to_peer_learning_network/screens/common/registration_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  // Smart navigation logic to check if a profile already exists
  Future<void> _navigateToRole(BuildContext context, UserRole role) async {
    final prefs = await SharedPreferences.getInstance();

    // THIS IS THE FIX: Check if the widget is still mounted after the await.
    if (!context.mounted) return;

    final roleString = role == UserRole.teacher ? 'teacher' : 'student';

    // Check if a user for this specific role exists
    if (prefs.containsKey('${roleString}_userName')) {
      // User exists, go to Login
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage(role: role)),
      );
    } else {
      // User does not exist, go to Registration
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RegistrationPage(role: role)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade200,
              Colors.purple.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 90,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to Learning Hub!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select your role to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white.withAlpha(230)),
                  ),
                  const SizedBox(height: 60),
                  _buildRoleCard(
                    context: context,
                    title: 'I am a Teacher',
                    icon: Icons.auto_stories_rounded,
                    color: Colors.white,
                    textColor: Colors.blue.shade700,
                    iconColor: Colors.blue.shade600,
                    onTap: () {
                      _navigateToRole(context, UserRole.teacher);
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildRoleCard(
                    context: context,
                    title: 'I am a Student',
                    icon: Icons.lightbulb_outline_rounded,
                    color: Colors.white,
                    textColor: Colors.purple.shade700,
                    iconColor: Colors.purple.shade600,
                    onTap: () {
                      _navigateToRole(context, UserRole.student);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: iconColor.withAlpha(25),
        highlightColor: iconColor.withAlpha(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: iconColor.withAlpha(38),
                child: Icon(icon, size: 30, color: iconColor),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: textColor.withAlpha(180)),
            ],
          ),
        ),
      ),
    );
  }
}