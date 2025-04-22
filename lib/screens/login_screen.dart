import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!mounted) return;

        if (userDoc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome back, ${userDoc['full_name']}!')),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background for a clean look
      appBar: AppBar(
        title: const Text('Accumulate Login'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.account_balance_wallet, size: 100, color: Colors.teal),
              const SizedBox(height: 20),
              const Text(
                "Welcome Back!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Login to continue managing your finances",
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your email';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.teal,
                  ),
                  child: const Text('Login', style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 20),

              // Create Account Button
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateAccountScreen()),
                  );
                },
                child: const Text(
                  "Don't have an account? Sign Up",
                  style: TextStyle(fontSize: 16, color: Colors.teal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

