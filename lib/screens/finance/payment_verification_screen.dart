import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';

class PaymentVerificationScreen extends StatefulWidget {
  const PaymentVerificationScreen({super.key});

  @override
  State<PaymentVerificationScreen> createState() => _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _verifyingBills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVerifyingBills();
  }

  Future<void> _fetchVerifyingBills() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('${ApiConstants.bills}?status=verification');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _verifyingBills = data is List ? data : (data['results'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetching verifying bills: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processVerification(int billId, String action) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.bills}$billId/approve-payment/',
        {'action': action},
      );
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(action == 'approve' ? 'Payment Approved!' : 'Payment Rejected.'),
              backgroundColor: action == 'approve' ? Colors.green : Colors.orange,
            ),
          );
        }
        _fetchVerifyingBills();
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Verifications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _verifyingBills.isEmpty
              ? const Center(child: Text('No payments pending verification.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _verifyingBills.length,
                  itemBuilder: (context, index) {
                    final bill = _verifyingBills[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Unit ${bill['unit_number'] ?? bill['unit']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                const Icon(Icons.info_outline, color: Colors.orange),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(bill['title'] ?? 'Maintenance', style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('₹${bill['amount']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _processVerification(bill['id'], 'reject'),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('Reject (Mark Pending)'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _processVerification(bill['id'], 'approve'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text('Approve (Mark Paid)'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
