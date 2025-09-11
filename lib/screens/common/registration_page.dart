import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peer_to_peer_learning_network/splash_page.dart';
import 'package:peer_to_peer_learning_network/screens/common/login_page.dart';
import 'package:peer_to_peer_learning_network/screens/common/widgets/wave_clipper.dart';

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
      final roleString = widget.role == UserRole.teacher ? 'teacher' : 'student';

      // CHANGED: Use role-specific keys for all data
      await prefs.setString('${roleString}_userName', _nameController.text);
      await prefs.setString('${roleString}_userPasscode', _passcodeController.text);

      if (widget.role == UserRole.teacher) {
        await prefs.setString('teacher_subject', _subjectController.text);
      } else {
        await prefs.setString('student_class', _classController.text);
        await prefs.setString('student_division', _divisionController.text);
      }

      // ADDED: Set this role as the last active one
      await prefs.setString('lastActiveRole', roleString);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration Successful! Please log in.')),
      );

      // CHANGED: Use pushAndRemoveUntil for a clean navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage(role: widget.role)),
            (route) => false,
      );
    }
  }

  // ... dispose method remains the same ...
  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _classController.dispose();
    _divisionController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  // ... build method and _inputDecoration remain the same ...
  @override
  Widget build(BuildContext context) {
    bool isTeacher = widget.role == UserRole.teacher;
    Color primaryColor = isTeacher ? Colors.indigo : Colors.green;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                ClipPath(
                  clipper: WaveClipper(),
                  child: Container(
                    height: 220,
                    color: primaryColor,
                  ),
                ),
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                Positioned(
                  top: 90,
                  left: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Join as a ${isTeacher ? 'Teacher' : 'Student'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Full Name', Icons.person_outline_rounded, primaryColor),
                      validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    if (isTeacher)
                      TextFormField(
                        controller: _subjectController,
                        decoration: _inputDecoration('Subject', Icons.book_outlined, primaryColor),
                        validator: (value) => value!.isEmpty ? 'Please enter your subject' : null,
                      ),
                    if (!isTeacher) ...[
                      TextFormField(
                        controller: _classController,
                        decoration: _inputDecoration('Class', Icons.class_outlined, primaryColor),
                        validator: (value) => value!.isEmpty ? 'Please enter your class' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _divisionController,
                        decoration: _inputDecoration('Division', Icons.group_outlined, primaryColor),
                        validator: (value) => value!.isEmpty ? 'Please enter your division' : null,
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passcodeController,
                      decoration: _inputDecoration('Create 4-Digit Passcode', Icons.lock_outline_rounded, primaryColor),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      validator: (value) => value!.length != 4 ? 'Passcode must be 4 digits' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _registerUser,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                      child: const Text('Complete Registration', style: TextStyle(fontSize: 16)),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, Color color) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: color.withAlpha(180)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 2),
      ),
    );
  }
}