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
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Transaction Name'),
            ),
            const SizedBox(height: 10),

            // Amount Field
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 10),

            // Category Dropdown (From Firestore Budgets Subcollection)
            FutureBuilder<QuerySnapshot>(
              future: _fetchCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print("Firestore Error: ${snapshot.error}");
                  return const Text("Error loading categories.");
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print("No budgets found for this user.");
                  return const Text("No categories found. Please add a budget first.");
                }

                List<String> categories = snapshot.data!.docs
                    .map((doc) => doc['category'].toString())
                    .toList();

                print("Categories from Firestore: $categories");

                // Ensure a default selection
                if (_selectedCategory == null && categories.isNotEmpty) {
                  _selectedCategory = categories.first;
                }

                return DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Category'),
                );
              },
            ),
            const SizedBox(height: 10),

            // Date Picker
            ListTile(
              title: Text("Date: ${_selectedDate.toLocal()}".split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
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
              },
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addTransaction,
                child: const Text('Add Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Fetch categories dynamically (Fix collection path)
  Future<QuerySnapshot> _fetchCategories() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ Error: No user is logged in!");
      throw Exception("User is not logged in.");
    }

    return FirebaseFirestore.instance.collection('users').doc(user.uid).collection('budget').get();
  }

  // ✅ Function to Add Transaction to Firestore
  void _addTransaction() async {
    String name = _nameController.text.trim();
    String amountText = _amountController.text.trim();

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No user logged in.')),
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
          .collection('transactions') // Save transactions under user
          .add({
        'name': name,
        'amount': amount,
        'category': _selectedCategory,
        'date': Timestamp.fromDate(_selectedDate), // Firestore format
      });

      print("✅ Transaction added: $name, Amount: $amount, Category: $_selectedCategory");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction Added Successfully!')),
      );

      Navigator.pop(context); // Go back to HomeScreen
    } catch (e) {
      print("❌ Error saving transaction: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving transaction: ${e.toString()}')),
      );
    }
  }
}



