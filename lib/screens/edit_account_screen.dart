import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key});

  @override
  _EditAccountScreenState createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    var userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    _nameController.text = userDoc['full_name'] ?? '';
    _emailController.text = user!.email ?? '';
  }

  Future<void> _updateAccount() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      if (_nameController.text.trim().isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'full_name': _nameController.text.trim(),
        });
      }

      if (_emailController.text.trim().isNotEmpty && _emailController.text.trim() != user!.email) {
        await user!.updateEmail(_emailController.text.trim());
      }

      if (_currentPasswordController.text.isNotEmpty &&
          _newPasswordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty) {
        await _changePassword();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (currentPassword == newPassword) {
      throw Exception("New password must be different from current password.");
    }

    // Reauthenticate
    AuthCredential credential = EmailAuthProvider.credential(
      email: user!.email!,
      password: currentPassword,
    );

    await user!.reauthenticateWithCredential(credential);
    await user!.updatePassword(newPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Account'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter an email' : null,
                    ),
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal),
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal),
                        ),
                      ),
                      validator: (value) {
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      onPressed: _updateAccount,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
