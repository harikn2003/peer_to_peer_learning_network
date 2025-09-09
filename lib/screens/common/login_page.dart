import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peer_to_peer_learning_network/splash_page.dart';
import 'package:peer_to_peer_learning_network/role_selection_page.dart';
import 'package:peer_to_peer_learning_network/screens/teacher/home_page.dart' as teacher;
import 'package:peer_to_peer_learning_network/screens/student/home_page.dart' as student;
// Removed: import 'package:peer_to_peer_learning_network/screens/common/widgets/wave_clipper.dart';

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

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _storedPasscode = prefs.getString('userPasscode') ?? '';
    });
  }

  void _validatePasscode(String enteredPasscode) {
    if (enteredPasscode == _storedPasscode) {
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
          behavior: SnackBarBehavior.floating, // Added for a more modern feel
        ),
      );
    }
  }

  Future<void> _resetAndGoToRoleSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

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
      height: 60, // Slightly increased height
      textStyle: TextStyle(fontSize: 22, color: primaryColor, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: Colors.white, // Filled background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1), // Subtle border
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: primaryColor, width: 2),
      ),
    );

    // final errorPinTheme = defaultPinTheme.copyWith(
    //   decoration: defaultPinTheme.decoration!.copyWith(
    //     border: Border.all(color: Colors.redAccent, width: 2),
    //   ),
    // );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container( // Replaced ClipPath with Container
                  height: 280, // Adjusted height
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only( // Added rounded corners
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                AppBar( // Kept AppBar for potential back navigation or title in future
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  // If you expect navigation to this page, ensure a back button appears or add one.
                  // leading: IconButton(
                  //   icon: Icon(Icons.arrow_back_ios_new_rounded),
                  //   onPressed: () => Navigator.of(context).pop(), // Example back navigation
                  // ),
                ),
                Positioned(
                  top: 100, // Adjusted position
                  child: Column(
                    children: [
                      Icon(isTeacher ? Icons.school_outlined : Icons.person_outline_rounded, size: 70, color: Colors.white), // Adjusted icon
                      const SizedBox(height: 12),
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 28, // Adjusted font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30), // Adjusted spacing
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0), // Added horizontal padding for content below header
              child: Column(
                children: [
                  Text(
                    'Hello, $_userName',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text( // Removed const
                    'Please enter your 4-digit passcode',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600), // Slightly darker grey
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28), // Adjusted spacing
                  Pinput(
                    length: 4,
                    onCompleted: _validatePasscode,
                    obscureText: true,
                    animationCurve: Curves.easeIn,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    // errorPinTheme: errorPinTheme, // Optional: for error state
                    // You might want to add a controller if you need to clear the Pinput programmatically
                    // controller: _pinController,
                  ),
                  const SizedBox(height: 35), // Adjusted spacing
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
            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
    );
  }
}
