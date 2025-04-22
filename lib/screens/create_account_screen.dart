import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  _CreateAccountScreenState createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String userId = userCredential.user!.uid;

        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'full_name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'created_at': Timestamp.now(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account Created Successfully')),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign Up Failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Consistent background
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.person_add_alt_1, size: 100, color: Colors.teal),
              const SizedBox(height: 20),
              const Text(
                "Let's Get Started!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Create your Accumulate account",
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your full name';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Email
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

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter a secure password',
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

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.teal,
                  ),
                  child: const Text('Create Account', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

