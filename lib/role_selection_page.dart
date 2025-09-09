import 'package:flutter/material.dart';
import 'package:peer_to_peer_learning_network/splash_page.dart'; // Assuming UserRole is here or in a shared file
import 'package:peer_to_peer_learning_network/screens/common/registration_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

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
            child: SingleChildScrollView( // Added for responsiveness on smaller screens
              padding: const EdgeInsets.all(32.0), // Increased padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined, // Changed icon for a slightly different feel
                    size: 90, // Slightly larger icon
                    color: Colors.white, // Changed from Colors.white70
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to Learning Hub!', // Simplified text
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32, // Increased font size
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Kept as Colors.white for strong contrast
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select your role to get started.', // Simplified text
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 60), // Increased spacing
                  _buildRoleCard(
                    context: context,
                    title: 'I am a Teacher',
                    icon: Icons.auto_stories_rounded, // Changed icon
                    color: Colors.white,
                    textColor: Colors.blue.shade700,
                    iconColor: Colors.blue.shade600,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const RegistrationPage(role: UserRole.teacher)),
                      );
                    },
                  ),
                  const SizedBox(height: 24), // Increased spacing
                  _buildRoleCard(
                    context: context,
                    title: 'I am a Student',
                    icon: Icons.lightbulb_outline_rounded, // Changed icon
                    color: Colors.white,
                    textColor: Colors.purple.shade700,
                    iconColor: Colors.purple.shade600,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const RegistrationPage(role: UserRole.student)),
                      );
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
    required Color color, // This will be card background
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5, // Increased elevation for more shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // More rounded corners
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20), // Match card's border radius
        splashColor: iconColor.withOpacity(0.1), // Themed splash color
        highlightColor: iconColor.withOpacity(0.05), // Themed highlight color
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24), // Adjusted padding
          child: Row(
            children: [
              CircleAvatar(
                radius: 28, // Slightly larger avatar
                backgroundColor: iconColor.withOpacity(0.15), // Softer background for avatar
                child: Icon(icon, size: 30, color: iconColor), // Icon color parameter
              ),
              const SizedBox(width: 24),
              Expanded( // Use Expanded to ensure text wraps if too long
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20, // Increased font size
                    fontWeight: FontWeight.w600, // Adjusted font weight
                    color: textColor, // Text color parameter
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: textColor.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
}