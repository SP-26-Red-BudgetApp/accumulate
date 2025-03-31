import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetDetailsScreen extends StatefulWidget {
  const BudgetDetailsScreen({super.key});

  @override
  _BudgetDetailsScreenState createState() => _BudgetDetailsScreenState();
}

class _BudgetDetailsScreenState extends State<BudgetDetailsScreen> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Breakdown')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Budget Categories',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // List of Budget Categories
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getUserBudgetStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No budget categories yet."));
                  }

                  var budgetDocs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: budgetDocs.length,
                    itemBuilder: (context, index) {
                      var budget = budgetDocs[index];
                      return ListTile(
                        title: Text(budget['category']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "\$${budget['amount'].toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editCategoryDialog(budget),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCategory(budget.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Add Category Button
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () => _showAddCategoryDialog(),
                child: const Text("Add Category"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Get budget stream for the logged-in user
  Stream<QuerySnapshot>? _getUserBudgetStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    
    return _firestore.collection('users').doc(user.uid).collection('budget').snapshots();
  }

  // ✅ Function to add a new budget category
  void _addCategory() async {
    String category = _categoryController.text.trim();
    double? amount = double.tryParse(_amountController.text);

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No user logged in.')),
      );
      return;
    }

    if (category.isNotEmpty && amount != null) {
      try {
        await _firestore.collection('users').doc(user.uid).collection('budget').add({
          'category': category,
          'amount': amount,
          'created_at': FieldValue.serverTimestamp(), // Helps with ordering
        });

        print("✅ Budget added: Category: $category, Amount: $amount");

        _categoryController.clear();
        _amountController.clear();
        Navigator.pop(context); // Close the dialog after adding
      } catch (e) {
        print("❌ Error adding budget: ${e.toString()}");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter category and amount.')),
      );
    }
  }

  // ✅ Function to update a budget category
  void _updateCategory(String docId, double newAmount) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).collection('budget').doc(docId).update({
      'amount': newAmount,
    });

    Navigator.pop(context);
  }

  // ✅ Function to delete a budget category
  void _deleteCategory(String docId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).collection('budget').doc(docId).delete();
  }

  // ✅ Show dialog to enter a new budget category
  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Budget Category"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: "Category Name"),
              ),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Amount"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: _addCategory,
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // ✅ Show dialog to edit a budget category
  void _editCategoryDialog(DocumentSnapshot budget) {
    _amountController.text = budget['amount'].toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit ${budget['category']}"),
          content: TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: "New Amount"),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                double? newAmount = double.tryParse(_amountController.text);
                if (newAmount != null) {
                  _updateCategory(budget.id, newAmount);
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }
}


