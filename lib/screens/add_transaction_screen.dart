import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Add Transaction'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transaction Details',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Transaction Name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Transaction Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              FutureBuilder<QuerySnapshot>(
                future: _fetchCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text("Error loading categories.");
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text("No categories found. Please add a budget first.");
                  }

                  List<String> categories = snapshot.data!.docs
                      .map((doc) => doc['category'].toString())
                      .toList();

                  // Default to first category if none selected yet
                  _selectedCategory ??= categories.isNotEmpty ? categories.first : null;

                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Date Picker
              ListTile(
                contentPadding: const EdgeInsets.all(0),
                title: const Text(
                  "Transaction Date",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${_selectedDate.toLocal()}".split(' ')[0],
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addTransaction,
                  icon: const Icon(Icons.check),
                  label: const Text('Save Transaction'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // ✅ Fetch categories dynamically
  Future<QuerySnapshot> _fetchCategories() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in.");
    }
    return FirebaseFirestore.instance.collection('users').doc(user.uid).collection('budget').get();
  }

  // ✅ Save Transaction
  void _addTransaction() async {
    String name = _nameController.text.trim();
    String amountText = _amountController.text.trim();
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No user logged in')),
      );
      return;
    }

    if (name.isEmpty || amountText.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    double amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add({
        'name': name,
        'amount': amount,
        'category': _selectedCategory,
        'date': Timestamp.fromDate(_selectedDate),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction Added Successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving transaction: $e')),
      );
    }
  }
}




