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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Budget Categories'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage your Budgets',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

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

                  return ListView.separated(
                    itemCount: budgetDocs.length,
                    separatorBuilder: (context, index) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      var budget = budgetDocs[index];
                      return ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: Text(
                          budget['category'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '\$${budget['amount'].toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.green, fontSize: 16),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddCategoryDialog,
                icon: const Icon(Icons.add),
                label: const Text("Add New Category", style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.teal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot>? _getUserBudgetStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    return _firestore.collection('users').doc(user.uid).collection('budget').snapshots();
  }

  void _addCategory() async {
    String category = _categoryController.text.trim();
    double? amount = double.tryParse(_amountController.text);

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in')),
      );
      return;
    }

    if (category.isNotEmpty && amount != null) {
      try {
        await _firestore.collection('users').doc(user.uid).collection('budget').add({
          'category': category,
          'amount': amount,
          'created_at': FieldValue.serverTimestamp(),
        });

        _categoryController.clear();
        _amountController.clear();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid category and amount')),
      );
    }
  }

  void _updateCategory(String docId, double newAmount) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).collection('budget').doc(docId).update({
      'amount': newAmount,
    });

    Navigator.pop(context);
  }

  void _deleteCategory(String docId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).collection('budget').doc(docId).delete();
  }

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
                decoration: const InputDecoration(
                  labelText: "Category Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(),
                ),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _editCategoryDialog(DocumentSnapshot budget) {
    _amountController.text = budget['amount'].toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit ${budget['category']}"),
          content: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "New Amount",
              border: OutlineInputBorder(),
            ),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }
}

