import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';

class MonthlyTrackerScreen extends StatefulWidget {
  const MonthlyTrackerScreen({super.key});

  @override
  State<MonthlyTrackerScreen> createState() => _MonthlyTrackerScreenState();
}

class _MonthlyTrackerScreenState extends State<MonthlyTrackerScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  List<dynamic> _allBills = [];
  List<dynamic> _paidBills = [];
  List<dynamic> _pendingBills = [];
  bool _isLoading = true;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchBills();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBills() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('${ApiConstants.bills}?month=$_selectedMonth');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bills = data is List ? data : (data['results'] ?? []);
        setState(() {
          _allBills = bills;
          _paidBills = bills.where((b) => b['status'] == 'paid').toList();
          _pendingBills = bills.where((b) => b['status'] == 'pending' || b['status'] == 'overdue').toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching bills: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markAsPaid(dynamic bill) async {
    final response = await _apiService.patch(
      '${ApiConstants.bills}${bill['id']}/',
      {'status': 'paid'},
    );
    if (response.statusCode == 200) {
      _fetchBills();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill marked as paid!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  String _generateCsvContent() {
    final buffer = StringBuffer();
    buffer.writeln('Unit,Title,Amount,Status,Due Date');
    for (final bill in _allBills) {
      buffer.writeln(
        '${bill['unit_number'] ?? bill['unit']},${bill['title']},${bill['amount']},${bill['status']},${bill['due_date']}'
      );
    }
    return buffer.toString();
  }

  void _exportToExcel() {
    final csv = _generateCsvContent();
    // Show CSV data in a dialog (for web, actual file download needs dart:html)
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export Data'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_allBills.length} records ready to export.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(csv, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
              ),
              const SizedBox(height: 8),
              const Text('Select all text above and paste into Excel/Sheets.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _changeMonth(int delta) {
    final parts = _selectedMonth.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]) + delta;
    if (month > 12) { month = 1; year++; }
    if (month < 1) { month = 12; year--; }
    setState(() => _selectedMonth = '$year-${month.toString().padLeft(2, '0')}');
    _fetchBills();
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime.parse('$_selectedMonth-01'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Tracker'),
        actions: [
          IconButton(icon: const Icon(Icons.file_download), onPressed: _exportToExcel, tooltip: 'Export CSV'),
        ],
      ),
      body: Column(
        children: [
          // Month Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.primaryColor.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
                Text(monthLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
              ],
            ),
          ),
          // Summary Cards
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _SummaryCard(label: 'Total', count: _allBills.length, color: Colors.blue),
                  const SizedBox(width: 12),
                  _SummaryCard(label: 'Paid', count: _paidBills.length, color: Colors.green),
                  const SizedBox(width: 12),
                  _SummaryCard(label: 'Pending', count: _pendingBills.length, color: Colors.red),
                ],
              ),
            ),
          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Paid'),
              Tab(text: 'Pending'),
            ],
          ),
          // Tab Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBillList(_allBills),
                      _buildBillList(_paidBills),
                      _buildBillList(_pendingBills),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillList(List<dynamic> bills) {
    if (bills.isEmpty) {
      return const Center(child: Text('No bills found for this period.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        final isPaid = bill['status'] == 'paid';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: isPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              child: Icon(isPaid ? Icons.check_circle : Icons.pending, color: isPaid ? Colors.green : Colors.red),
            ),
            title: Text(bill['unit_number'] ?? 'Unit ${bill['unit']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(bill['title'] ?? 'Maintenance'),
                Text('Due: ${bill['due_date']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${bill['amount']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                if (!isPaid)
                  InkWell(
                    onTap: () => _markAsPaid(bill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Mark Paid', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  const Text('PAID', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryCard({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
