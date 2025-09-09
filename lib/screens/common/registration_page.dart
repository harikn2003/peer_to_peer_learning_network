import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peer_to_peer_learning_network/splash_page.dart';
import 'package:peer_to_peer_learning_network/screens/common/login_page.dart';
// Removed WaveClipper import as it's no longer used

class RegistrationPage extends StatefulWidget {
  final UserRole role;
  const RegistrationPage({super.key, required this.role});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _classController = TextEditingController();
  final _divisionController = TextEditingController();
  final _passcodeController = TextEditingController();

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _nameController.text);
      await prefs.setString('userPasscode', _passcodeController.text);

      if (widget.role == UserRole.teacher) {
        await prefs.setString('userRole', 'teacher');
        await prefs.setString('subject', _subjectController.text);
      } else {
        await prefs.setString('userRole', 'student');
        await prefs.setString('class', _classController.text);
        await prefs.setString('division', _divisionController.text);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration Successful! Please log in.')),
      );

      Navigator.pushReplacement( // Changed to pushReplacement to prevent going back to registration
        context,
        MaterialPageRoute(builder: (context) => LoginPage(role: widget.role)),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _classController.dispose();
    _divisionController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isTeacher = widget.role == UserRole.teacher;
    Color primaryColor = isTeacher ? Colors.indigo.shade400 : Colors.green.shade400; // Slightly lighter shades

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Background color consistent with new input fields
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container( // Replaced ClipPath with Container
                  height: 230, // Adjusted height
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40), // More pronounced rounding
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  leading: IconButton( // Explicit back button for clarity
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  top: 90, // Adjusted positioning
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      const Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30, // Slightly adjusted
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Join as a ${isTeacher ? 'Teacher' : 'Student'}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withAlpha(220), // More opaque
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24.0), // Consistent padding
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20), // Increased spacing
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Full Name', Icons.person_outline_rounded, primaryColor),
                      validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 18), // Adjusted spacing
                    if (isTeacher)
                      TextFormField(
                        controller: _subjectController,
                        decoration: _inputDecoration('Subject Taught', Icons.book_outlined, primaryColor),
                        validator: (value) => value!.isEmpty ? 'Please enter your subject' : null,
                      ),
                    if (!isTeacher) ...[
                      TextFormField(
                        controller: _classController,
                        decoration: _inputDecoration('Your Class (e.g., 10th)', Icons.class_outlined, primaryColor),
                        validator: (value) => value!.isEmpty ? 'Please enter your class' : null,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _divisionController,
                        decoration: _inputDecoration('Division (e.g., A)', Icons.group_work_outlined, primaryColor),
                        validator: (value) => value!.isEmpty ? 'Please enter your division' : null,
                      ),
                    ],
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _passcodeController,
                      decoration: _inputDecoration('Create 4-Digit Passcode', Icons.lock_outline_rounded, primaryColor),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      validator: (value) => value != null && value.length == 4 ? null : 'Passcode must be 4 digits',
                    ),
                    const SizedBox(height: 30), // Increased spacing before button
                    ElevatedButton(
                      onPressed: _registerUser,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52), // Slightly taller button
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4, // Slightly more elevation
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
                      ),
                      child: const Text('Complete Registration'),
                    ),
                    const SizedBox(height: 20),
                     GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage(role: widget.role)),
                        );
                      },
                      child: Text(
                        'Already have an account? Log In',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, Color color) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: color.withAlpha(200)),
      filled: true,
      fillColor: Colors.white, // Changed fill color for better contrast with grey.shade100 background
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder( // Subtle border when enabled
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0), // Adjusted padding
    );
  }
}
