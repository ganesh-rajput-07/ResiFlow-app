import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.financeSummary);
      if (response.statusCode == 200) {
        setState(() => _summary = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching finance summary: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finance Overview')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchSummary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Society Balance Hero Card ---
                    _BalanceCard(
                      balance: (_summary['society_balance'] ?? 0).toDouble(),
                      totalIncome: (_summary['total_income'] ?? 0).toDouble(),
                      totalExpenses: (_summary['total_expenses'] ?? 0).toDouble(),
                    ),
                    const SizedBox(height: 24),

                    // --- Income Breakdown ---
                    const Text('Income Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniCard(
                            label: 'Maintenance',
                            amount: (_summary['total_maintenance_collected'] ?? 0).toDouble(),
                            icon: Icons.home,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniCard(
                            label: 'Penalties',
                            amount: (_summary['total_penalties_collected'] ?? 0).toDouble(),
                            icon: Icons.gavel,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _MiniCard(
                      label: 'Other Income',
                      amount: (_summary['total_other_income'] ?? 0).toDouble(),
                      icon: Icons.account_balance_wallet,
                      color: Colors.teal,
                      fullWidth: true,
                    ),
                    const SizedBox(height: 24),

                    // --- Pending Collections ---
                    const Text('Pending Collections', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniCard(
                            label: 'Bills Pending',
                            amount: (_summary['pending_bill_amount'] ?? 0).toDouble(),
                            icon: Icons.receipt_long,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniCard(
                            label: 'Penalties Due',
                            amount: (_summary['pending_penalty_amount'] ?? 0).toDouble(),
                            icon: Icons.warning_amber,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Expense Breakdown ---
                    if ((_summary['expense_breakdown'] as List?)?.isNotEmpty ?? false) ...[
                      const Text('Expense Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._buildExpenseBreakdown(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildExpenseBreakdown() {
    final breakdown = List<Map<String, dynamic>>.from(_summary['expense_breakdown'] ?? []);
    final categoryLabels = {
      'electricity': 'Electricity',
      'water': 'Water',
      'security': 'Security',
      'cleaning': 'Cleaning',
      'gardening': 'Gardening',
      'repairs': 'Repairs',
      'lift': 'Lift',
      'insurance': 'Insurance',
      'legal': 'Legal',
      'events': 'Events',
      'salary': 'Salary',
      'taxes': 'Taxes',
      'sinking_fund': 'Sinking Fund',
      'other': 'Other',
    };
    final categoryIcons = {
      'electricity': Icons.bolt,
      'water': Icons.water_drop,
      'security': Icons.security,
      'cleaning': Icons.cleaning_services,
      'gardening': Icons.park,
      'repairs': Icons.build,
      'lift': Icons.elevator,
      'insurance': Icons.shield,
      'legal': Icons.balance,
      'events': Icons.celebration,
      'salary': Icons.people,
      'taxes': Icons.receipt,
      'sinking_fund': Icons.savings,
      'other': Icons.more_horiz,
    };
    final categoryColors = {
      'electricity': Colors.amber,
      'water': Colors.cyan,
      'security': Colors.indigo,
      'cleaning': Colors.green,
      'gardening': Colors.lightGreen,
      'repairs': Colors.brown,
      'lift': Colors.blueGrey,
      'insurance': Colors.purple,
      'legal': Colors.deepPurple,
      'events': Colors.pink,
      'salary': Colors.teal,
      'taxes': Colors.red,
      'sinking_fund': Colors.blue,
      'other': Colors.grey,
    };

    final totalExp = (_summary['total_expenses'] ?? 1).toDouble();

    return breakdown.map((item) {
      final cat = item['category'] ?? 'other';
      final total = (item['total'] is String ? double.tryParse(item['total']) : item['total']?.toDouble()) ?? 0.0;
      final pct = totalExp > 0 ? (total / totalExp) : 0.0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (categoryColors[cat] ?? Colors.grey).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(categoryIcons[cat] ?? Icons.more_horiz, color: categoryColors[cat] ?? Colors.grey, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(categoryLabels[cat] ?? cat, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.grey.shade200,
                        color: categoryColors[cat] ?? Colors.grey,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
      );
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// Balance Hero Card
// ---------------------------------------------------------------------------
class _BalanceCard extends StatelessWidget {
  final double balance;
  final double totalIncome;
  final double totalExpenses;

  const _BalanceCard({required this.balance, required this.totalIncome, required this.totalExpenses});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F3A5F), Color(0xFF102138)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Society Balance', style: TextStyle(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '₹ ${balance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Income', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        Text('₹${totalIncome.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.arrow_upward, color: Colors.redAccent, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expenses', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        Text('₹${totalExpenses.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini Stat Card
// ---------------------------------------------------------------------------
class _MiniCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  const _MiniCard({required this.label, required this.amount, required this.icon, required this.color, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 4),
                Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
