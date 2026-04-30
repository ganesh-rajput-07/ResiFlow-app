import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';

class ResidentPaymentsScreen extends StatefulWidget {
  const ResidentPaymentsScreen({super.key});

  @override
  State<ResidentPaymentsScreen> createState() => _ResidentPaymentsScreenState();
}

class _ResidentPaymentsScreenState extends State<ResidentPaymentsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  List<dynamic> _currentBills = [];
  List<dynamic> _historyBills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final response = await _apiService.get(ApiConstants.bills);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bills = data is List ? data : (data['results'] ?? []);
        final now = DateTime.now();
        final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

        setState(() {
          _currentBills = bills.where((b) {
            final created = b['created_at'] ?? '';
            return created.startsWith(currentMonth);
          }).toList();
          _historyBills = bills.where((b) {
            final created = b['created_at'] ?? '';
            return !created.startsWith(currentMonth);
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching bills: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showInvoice(dynamic bill) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Invoice Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long, color: AppTheme.primaryColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('INVOICE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Details
              _InvoiceRow(label: 'Invoice #', value: 'INV-${bill['id'].toString().padLeft(5, '0')}'),
              _InvoiceRow(label: 'Title', value: bill['title'] ?? 'Maintenance'),
              _InvoiceRow(label: 'Unit', value: bill['unit_number'] ?? 'Unit ${bill['unit']}'),
              _InvoiceRow(label: 'Due Date', value: bill['due_date'] ?? 'N/A'),
              _InvoiceRow(label: 'Status', value: (bill['status'] ?? 'pending').toUpperCase()),
              const Divider(height: 24),

              // Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('₹${bill['amount']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                ],
              ),
              const SizedBox(height: 8),
              if (bill['status'] == 'paid')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      SizedBox(width: 4),
                      Text('PAID', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              // Copy / Share actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Generate text invoice for sharing
                        final text = '''
INVOICE #INV-${bill['id'].toString().padLeft(5, '0')}
${bill['title'] ?? 'Maintenance'}
Unit: ${bill['unit_number'] ?? bill['unit']}
Amount: ₹${bill['amount']}
Due: ${bill['due_date']}
Status: ${(bill['status'] ?? 'pending').toUpperCase()}
''';
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invoice copied!'), backgroundColor: Colors.green),
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentOptions(dynamic bill) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pay Maintenance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('₹${bill['amount']}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              const SizedBox(height: 24),

              // UPI Payment
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.qr_code, color: Colors.purple),
                ),
                title: const Text('Pay via UPI', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Google Pay, PhonePe, Paytm...'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('UPI payment link will open your UPI app')),
                  );
                },
              ),
              const Divider(),

              // Bank Transfer
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.account_balance, color: Colors.blue),
                ),
                title: const Text('Bank Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('NEFT / IMPS / RTGS'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bank details copied to clipboard')),
                  );
                },
              ),
              const Divider(),

              // Cash
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.money, color: Colors.green),
                ),
                title: const Text('Pay in Cash', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Contact admin for cash payment'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Payments'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Current Month'),
            Tab(text: 'Payment History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Current Month
                _currentBills.isEmpty
                    ? const Center(child: Text('No bills for this month yet.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _currentBills.length,
                        itemBuilder: (context, index) => _buildBillCard(_currentBills[index], isCurrent: true),
                      ),
                // History
                _historyBills.isEmpty
                    ? const Center(child: Text('No payment history yet.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _historyBills.length,
                        itemBuilder: (context, index) => _buildBillCard(_historyBills[index], isCurrent: false),
                      ),
              ],
            ),
    );
  }

  Widget _buildBillCard(dynamic bill, {required bool isCurrent}) {
    final isPaid = bill['status'] == 'paid';
    final dueDate = bill['due_date'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(bill['title'] ?? 'Maintenance', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isPaid ? Colors.green : Colors.red),
                  ),
                  child: Text(
                    isPaid ? 'PAID' : 'PENDING',
                    style: TextStyle(color: isPaid ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Amount
            Text('₹${bill['amount']}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(height: 8),
            Text('Due: $dueDate', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showInvoice(bill),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Invoice'),
                  ),
                ),
                if (!isPaid && isCurrent) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showPaymentOptions(bill),
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Pay Now'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final String label;
  final String value;
  const _InvoiceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
