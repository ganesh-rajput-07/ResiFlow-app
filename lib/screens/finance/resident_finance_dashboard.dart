import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';

class ResidentFinanceDashboard extends StatefulWidget {
  const ResidentFinanceDashboard({super.key});

  @override
  State<ResidentFinanceDashboard> createState() => _ResidentFinanceDashboardState();
}

class _ResidentFinanceDashboardState extends State<ResidentFinanceDashboard> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _summary = {};
  List<dynamic> _recentExpenses = [];
  List<dynamic> _recentIncome = [];

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _apiService.get(ApiConstants.financeSummary),
        _apiService.get('${ApiConstants.expenses}?limit=5'),
        _apiService.get('${ApiConstants.income}?limit=5'),
      ]);

      if (futures[0].statusCode == 200) {
        _summary = jsonDecode(futures[0].body);
      }
      if (futures[1].statusCode == 200) {
        final d = jsonDecode(futures[1].body);
        _recentExpenses = (d is List ? d : List.from(d['results'] ?? [])).take(5).toList();
      }
      if (futures[2].statusCode == 200) {
        final d = jsonDecode(futures[2].body);
        _recentIncome = (d is List ? d : List.from(d['results'] ?? [])).take(5).toList();
      }
    } catch (e) {
      debugPrint('Error fetching finance data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static const _expenseCategoryInfo = {
    'electricity': ('Electricity', Icons.bolt, Colors.amber),
    'water': ('Water', Icons.water_drop, Colors.cyan),
    'security': ('Security', Icons.security, Colors.indigo),
    'cleaning': ('Cleaning', Icons.cleaning_services, Colors.green),
    'gardening': ('Gardening', Icons.park, Colors.lightGreen),
    'repairs': ('Repairs', Icons.build, Colors.brown),
    'lift': ('Lift', Icons.elevator, Colors.blueGrey),
    'insurance': ('Insurance', Icons.shield, Colors.purple),
    'legal': ('Legal', Icons.balance, Colors.deepPurple),
    'events': ('Events', Icons.celebration, Colors.pink),
    'salary': ('Salary', Icons.people, Colors.teal),
    'taxes': ('Taxes', Icons.receipt, Colors.red),
    'sinking_fund': ('Sinking Fund', Icons.savings, Colors.blue),
    'other': ('Other', Icons.more_horiz, Colors.grey),
  };

  static const _incomeCategoryInfo = {
    'maintenance': ('Maintenance', Icons.home, Colors.blue),
    'penalty_collection': ('Penalty', Icons.gavel, Colors.orange),
    'parking_rent': ('Parking Rent', Icons.local_parking, Colors.indigo),
    'hall_booking': ('Hall Booking', Icons.meeting_room, Colors.purple),
    'interest': ('Bank Interest', Icons.account_balance, Colors.teal),
    'deposit': ('Deposit', Icons.savings, Colors.green),
    'other': ('Other', Icons.more_horiz, Colors.grey),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Society Finance')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Balance Hero Card ───
                    _buildBalanceCard(),
                    const SizedBox(height: 24),

                    // ─── Income Sources ───
                    _buildSectionTitle('Where does income come from?'),
                    const SizedBox(height: 12),
                    _buildIncomeBreakdown(),
                    const SizedBox(height: 24),

                    // ─── Expense Breakdown ───
                    _buildSectionTitle('Where do expenses go?'),
                    const SizedBox(height: 12),
                    _buildExpenseBreakdown(),
                    const SizedBox(height: 24),

                    // ─── Pending ───
                    _buildSectionTitle('Pending Collections'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatChip('Bills Pending', _summary['pending_bill_amount'], Colors.red, Icons.receipt_long)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatChip('Penalties Due', _summary['pending_penalty_amount'], Colors.deepOrange, Icons.warning_amber)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Recent Expenses ───
                    if (_recentExpenses.isNotEmpty) ...[
                      _buildSectionTitle('Recent Expenses'),
                      const SizedBox(height: 12),
                      ..._recentExpenses.map((e) {
                        final cat = e['category'] ?? 'other';
                        final info = _expenseCategoryInfo[cat] ?? ('Other', Icons.more_horiz, Colors.grey);
                        return _buildTransactionTile(e['title'] ?? '', '₹${e['amount']}', e['expense_date'] ?? '', info.$2, info.$3, false);
                      }),
                      const SizedBox(height: 24),
                    ],

                    // ─── Recent Income ───
                    if (_recentIncome.isNotEmpty) ...[
                      _buildSectionTitle('Recent Income'),
                      const SizedBox(height: 12),
                      ..._recentIncome.map((r) {
                        final cat = r['category'] ?? 'other';
                        final info = _incomeCategoryInfo[cat] ?? ('Other', Icons.more_horiz, Colors.grey);
                        return _buildTransactionTile(r['title'] ?? '', '₹${r['amount']}', r['income_date'] ?? '', info.$2, info.$3, true);
                      }),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = (_summary['society_balance'] ?? 0).toDouble();
    final totalIncome = (_summary['total_income'] ?? 0).toDouble();
    final totalExpenses = (_summary['total_expenses'] ?? 0).toDouble();

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
          Row(
            children: [
              const Icon(Icons.account_balance, color: Colors.white54, size: 18),
              const SizedBox(width: 8),
              const Text('Society Balance', style: TextStyle(color: Colors.white60, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₹ ${_formatAmount(balance)}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
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
                          const Text('Total Income', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          Text('₹${_formatAmount(totalIncome)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: Colors.white12),
                const SizedBox(width: 12),
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
                          const Text('Total Expenses', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          Text('₹${_formatAmount(totalExpenses)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeBreakdown() {
    final maintenanceCollected = (_summary['total_maintenance_collected'] ?? 0).toDouble();
    final penaltiesCollected = (_summary['total_penalties_collected'] ?? 0).toDouble();
    final otherIncome = (_summary['total_other_income'] ?? 0).toDouble();
    final total = (_summary['total_income'] ?? 1).toDouble();

    final items = [
      ('Maintenance', maintenanceCollected, Colors.blue, Icons.home),
      ('Penalty Collections', penaltiesCollected, Colors.orange, Icons.gavel),
      ('Other Income', otherIncome, Colors.teal, Icons.account_balance_wallet),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        children: items.map((item) {
          final pct = total > 0 ? item.$2 / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: item.$3.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(item.$4, color: item.$3, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('₹${_formatAmount(item.$2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: item.$3)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: pct, backgroundColor: Colors.grey.shade200, color: item.$3, minHeight: 5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpenseBreakdown() {
    final breakdown = List<Map<String, dynamic>>.from(_summary['expense_breakdown'] ?? []);
    if (breakdown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('No expenses recorded', style: TextStyle(color: Colors.grey))),
      );
    }

    final totalExp = (_summary['total_expenses'] ?? 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        children: breakdown.map((item) {
          final cat = item['category'] ?? 'other';
          final info = _expenseCategoryInfo[cat] ?? ('Other', Icons.more_horiz, Colors.grey);
          final total = (item['total'] is String ? double.tryParse(item['total']) : item['total']?.toDouble()) ?? 0.0;
          final pct = totalExp > 0 ? total / totalExp : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: info.$3.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(info.$2, color: info.$3, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(info.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('₹${_formatAmount(total)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: info.$3)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: pct, backgroundColor: Colors.grey.shade200, color: info.$3, minHeight: 5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatChip(String label, dynamic value, Color color, IconData icon) {
    final amount = (value ?? 0).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                const SizedBox(height: 2),
                Text('₹${_formatAmount(amount)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(String title, String amount, String date, IconData icon, Color color, bool isIncome) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isIncome ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }

  String _formatAmount(double val) {
    if (val >= 10000000) return '${(val / 10000000).toStringAsFixed(1)}Cr';
    if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
  }
}
