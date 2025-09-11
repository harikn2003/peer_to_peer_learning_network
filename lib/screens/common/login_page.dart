import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peer_to_peer_learning_network/splash_page.dart';
import 'package:peer_to_peer_learning_network/role_selection_page.dart';
import 'package:peer_to_peer_learning_network/screens/teacher/home_page.dart' as teacher;
import 'package:peer_to_peer_learning_network/screens/student/home_page.dart' as student;

class LoginPage extends StatefulWidget {
  final UserRole role;
  const LoginPage({super.key, required this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _userName = '';
  String _storedPasscode = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // LOGIC FIX 1: Loads role-specific user data
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = widget.role == UserRole.teacher ? 'teacher' : 'student';
    setState(() {
      _userName = prefs.getString('${roleString}_userName') ?? 'User';
      _storedPasscode = prefs.getString('${roleString}_userPasscode') ?? '';
    });
  }

  // LOGIC FIX 2: Saves the active role on successful login
  Future<void> _validatePasscode(String enteredPasscode) async {
    if (enteredPasscode == _storedPasscode) {
      final prefs = await SharedPreferences.getInstance();
      final roleString = widget.role == UserRole.teacher ? 'teacher' : 'student';
      await prefs.setString('lastActiveRole', roleString);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => widget.role == UserRole.teacher
              ? const teacher.TeacherHomePage()
              : const student.StudentHomePage(),
        ),
            (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect Passcode. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // LOGIC FIX 3: Safely switches role without deleting data
  Future<void> _resetAndGoToRoleSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastActiveRole'); // Does NOT delete user profiles

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isTeacher = widget.role == UserRole.teacher;
    Color primaryColor = isTeacher ? Colors.blue.shade700 : Colors.teal.shade700;
    Color secondaryColor = isTeacher ? Colors.blue.shade200 : Colors.teal.shade200;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: TextStyle(fontSize: 22, color: primaryColor, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: primaryColor, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                Positioned(
                  top: 100,
                  child: Column(
                    children: [
                      Icon(isTeacher ? Icons.school_outlined : Icons.person_outline_rounded, size: 70, color: Colors.white),
                      const SizedBox(height: 12),
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    'Hello, $_userName',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please enter your 4-digit passcode',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Pinput(
                    length: 4,
                    onCompleted: _validatePasscode,
                    obscureText: true,
                    animationCurve: Curves.easeIn,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                  ),
                  const SizedBox(height: 35),
                  TextButton(
                    onPressed: _resetAndGoToRoleSelection,
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        )
                    ),
                    child: Text(
                      'Switch Role / Register New User',
                      style: TextStyle(color: primaryColor, fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}