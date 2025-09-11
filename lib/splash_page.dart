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
    // CHANGED: Check for the last active role instead of a generic one
    final lastActiveRole = prefs.getString('lastActiveRole');

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (lastActiveRole != null) {
      // A user was previously active, go to their Login Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(
            role: lastActiveRole == 'teacher' ? UserRole.teacher : UserRole.student,
          ),
        ),
      );
    } else {
      // No user has ever logged in, go to Role Selection
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

// This enum is still very useful
enum UserRole { teacher, student }