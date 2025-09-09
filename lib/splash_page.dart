import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peer_to_peer_learning_network/role_selection_page.dart';
import 'package:peer_to_peer_learning_network/screens/common/login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('userRole');

    // Wait for 2 seconds to show a splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (userRole != null) {
      // User is registered, go to Login Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(
            role: userRole == 'teacher' ? UserRole.teacher : UserRole.student,
          ),
        ),
      );
    } else {
      // No user found, go to Role Selection
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cast_for_education, size: 100, color: Colors.indigo),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// Define an enum for user roles to avoid typos
enum UserRole { teacher, student }