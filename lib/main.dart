import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart'; // Import LoginScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AccumulateApp());
}

class AccumulateApp extends StatelessWidget {
  const AccumulateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accumulate - Finance Budgeting',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(), // Uses the separate login_screen.dart
    );
  }
}
