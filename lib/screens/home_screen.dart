import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'add_transaction_screen.dart';
import 'budget_details_screen.dart';
import 'login_screen.dart'; // Ensure this is included

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String fullName = 'Loading...';
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // ✅ Fetch user's full name
  void _fetchUserData() async {
    if (user == null) return;

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    
    if (userDoc.exists && userDoc.data() != null) {
      setState(() {
        fullName = userDoc['full_name'] ?? 'User';
      });
      print("✅ Fetched user full name: $fullName");
    } else {
      print("❌ No user document found.");
    }
  }

  // ✅ Logout Function
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $fullName', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // ✅ Budget Chart (Live Updates)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BudgetDetailsScreen()),
                );
              },
              child: SizedBox(
                height: 200,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .collection('budget')
                      .snapshots(),
                  builder: (context, budgetSnapshot) {
                    if (!budgetSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final budgetDocs = budgetSnapshot.data!.docs;
                    if (budgetDocs.isEmpty) {
                      return const Center(child: Text('No budgets available.'));
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user?.uid)
                          .collection('transactions')
                          .snapshots(),
                      builder: (context, transactionSnapshot) {
                        if (!transactionSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                        final transactionDocs = transactionSnapshot.data!.docs;

                        // Calculate spent amount for each category
                        Map<String, double> spentPerCategory = {};
                        for (var transaction in transactionDocs) {
                          String category = transaction['category'];
                          double amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                          spentPerCategory[category] = (spentPerCategory[category] ?? 0) + amount;
                        }

                        return BarChart(
                          BarChartData(
                            barGroups: budgetDocs.map((budget) {
                              String category = budget['category'];
                              double budgeted = (budget['amount'] as num?)?.toDouble() ?? 0.0;
                              double spent = spentPerCategory[category] ?? 0.0;

                              return BarChartGroupData(
                                x: budgetDocs.indexOf(budget),
                                barRods: [
                                  BarChartRodData(
                                    fromY: 0,
                                    toY: spent,
                                    width: 16,
                                    color: Colors.blue.shade800,
                                    borderRadius: BorderRadius.circular(4),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: budgeted,
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(show: false),
                            gridData: FlGridData(show: false),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ✅ Recent Transactions Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Recent Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 10),

          // ✅ Recent Transactions List (Live Updates)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .collection('transactions')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final transactionDocs = snapshot.data!.docs;
                if (transactionDocs.isEmpty) {
                  return const Center(child: Text('No transactions recorded.'));
                }

                return ListView.builder(
                  itemCount: transactionDocs.length,
                  itemBuilder: (context, index) {
                    var transaction = transactionDocs[index];
                    String name = transaction['name'];
                    double amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                    String category = transaction['category'];

                    return ListTile(
                      title: Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: Text(category, style: TextStyle(color: Colors.grey)),
                      trailing: Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, color: Colors.green),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ✅ Floating Action Button (FAB) for Adding Budget & Transactions
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddOptions(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ✅ Show Add Options Modal
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text("Add Budget Category"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BudgetDetailsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text("Add Transaction"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTransactionScreen()));
              },
            ),
          ],
        );
      },
    );
  }
}





