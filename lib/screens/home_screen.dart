import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'add_transaction_screen.dart';
import 'budget_details_screen.dart';
import 'login_screen.dart';
import 'edit_account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String fullName = 'Loading...';
  final User? user = FirebaseAuth.instance.currentUser;
  late AnimationController _controller;
  bool _overBudgetAlertShown = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fetchUserData() async {
    if (user == null) return;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      setState(() {
        fullName = userDoc['full_name'] ?? 'User';
      });
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _checkOverBudget(Map<String, double> spentPerCategory, Map<String, double> budgetedPerCategory) {
    if (_overBudgetAlertShown) return;

    for (var category in spentPerCategory.keys) {
      if (budgetedPerCategory.containsKey(category) &&
          spentPerCategory[category]! > budgetedPerCategory[category]!) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ You have exceeded your budget for $category!'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
          _overBudgetAlertShown = true;
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text('Welcome, $fullName', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditAccountScreen()));
              } else if (value == 'logout'){
                 _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Account'),
                ),
                ),
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

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FadeTransition(
              opacity: _controller,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 6,
                shadowColor: Colors.tealAccent,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Budget Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetDetailsScreen()));
                            },
                            child: const Icon(Icons.arrow_forward_ios, size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 220,
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
                              return const Center(child: Text('No budget categories.'));
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

                                Map<String, double> spentPerCategory = {};
                                Map<String, double> budgetedPerCategory = {};

                                for (var transaction in transactionDocs) {
                                  String category = transaction['category'];
                                  double amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                                  spentPerCategory[category] = (spentPerCategory[category] ?? 0) + amount;
                                }

                                for (var budget in budgetDocs) {
                                  String category = budget['category'];
                                  double amount = (budget['amount'] as num?)?.toDouble() ?? 0.0;
                                  budgetedPerCategory[category] = amount;
                                }

                                _checkOverBudget(spentPerCategory, budgetedPerCategory);

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
                                            width: 14,
                                            color: spent > budgeted ? Colors.redAccent : Colors.teal.shade700,
                                            borderRadius: BorderRadius.circular(4),
                                            backDrawRodData: BackgroundBarChartRodData(
                                              show: true,
                                              toY: budgeted,
                                              color: Colors.teal.shade200,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                    borderData: FlBorderData(show: false),
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (double value, TitleMeta meta) {
                                            if (value.toInt() < 0 || value.toInt() >= budgetDocs.length) return const SizedBox.shrink();
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(
                                                budgetDocs[value.toInt()]['category'],
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                            );
                                          },
                                          reservedSize: 36,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 100,
                                          getTitlesWidget: (double value, TitleMeta meta) {
                                            return Text(
                                              '\$${value.toInt()}',
                                              style: const TextStyle(fontSize: 10),
                                            );
                                          },
                                          reservedSize: 40,
                                          ),
                                        ),
                                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Recent Transactions
            FadeTransition(
              opacity: _controller,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

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
                    return const Center(child: Text('No transactions yet.'));
                  }

                  return ListView.builder(
                    itemCount: transactionDocs.length,
                    itemBuilder: (context, index) {
                      var transaction = transactionDocs[index];
                      String name = transaction['name'];
                      double amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                      String category = transaction['category'];

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.monetization_on, color: Colors.teal),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(category),
                          trailing: Text('\$${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        onPressed: () {
          _showAddOptions(context);
        },
        label: const Text("Add"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.teal),
              title: const Text("Add Budget Category"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BudgetDetailsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.teal),
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






