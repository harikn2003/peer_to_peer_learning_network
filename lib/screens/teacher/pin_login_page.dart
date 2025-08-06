import 'package:flutter/material.dart';
import 'package:peer_to_peer_learning_network/screens/teacher/home_page.dart';
import 'package:pinput/pinput.dart';

class PinLoginPage extends StatelessWidget {
  const PinLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Teacher Login'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 60, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Enter Your PIN',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Pinput(
              length: 4,
              pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
              showCursor: true,
              onCompleted: (pin) {
                // For UI demo, any pin navigates to home
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const TeacherHomePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}