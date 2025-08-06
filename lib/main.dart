import 'package:flutter/material.dart';
import 'package:peer_to_peer_learning_network/role_selection_page.dart';

void main() {
  runApp(const OfflineLearningApp());
}

class OfflineLearningApp extends StatelessWidget {
  const OfflineLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Learning Hub',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const RoleSelectionPage(),
    );
  }
}