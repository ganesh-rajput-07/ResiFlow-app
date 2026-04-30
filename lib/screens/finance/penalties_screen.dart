import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class PenaltiesScreen extends StatefulWidget {
  const PenaltiesScreen({super.key});

  @override
  State<PenaltiesScreen> createState() => _PenaltiesScreenState();
}

class _PenaltiesScreenState extends State<PenaltiesScreen> {
  final ApiService _apiService = ApiService();
  final _targetController = TextEditingController();
  final _reasonController = TextEditingController();
  final _amountController = TextEditingController();

  List<dynamic> _penalties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPenalties();
  }

  Future<void> _fetchPenalties() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.penalties);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _penalties = data is List ? data : (data['results'] ?? []));
      }
    } catch (e) {
      debugPrint('Error fetching penalties: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showIssuePenaltySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Issue New Penalty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CustomTextField(controller: _targetController, label: 'Target Unit/Resident', hint: 'e.g. A-102'),
              const SizedBox(height: 12),
              CustomTextField(controller: _reasonController, label: 'Reason', hint: 'e.g. Trash placed in corridor'),
              const SizedBox(height: 12),
              CustomTextField(controller: _amountController, label: 'Penalty Amount (₹)', hint: '500', keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              CustomButton(text: 'Issue Penalty', onPressed: () async {
                final response = await _apiService.post(ApiConstants.penalties, {
                  'reason': _reasonController.text,
                  'amount': _amountController.text,
                });

                if (response.statusCode == 201 && mounted) {
                  _targetController.clear();
                  _reasonController.clear();
                  _amountController.clear();
                  Navigator.pop(context);
                  _fetchPenalties();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penalty issued.'), backgroundColor: Colors.green));
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${response.body}'), backgroundColor: Colors.red));
                }
              }),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Penalties')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _penalties.isEmpty
              ? const Center(child: Text('No penalties issued.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _penalties.length,
                  itemBuilder: (context, index) {
                    final p = _penalties[index];
                    final isPaid = p['status'] == 'paid';
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: isPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          child: Icon(Icons.gavel, color: isPaid ? Colors.green : Colors.red),
                        ),
                        title: Text('₹${p['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(p['reason'] ?? 'No reason'),
                            const SizedBox(height: 4),
                            Text(
                              isPaid ? 'PAID' : 'UNPAID',
                              style: TextStyle(color: isPaid ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: !isPaid
                            ? InkWell(
                                onTap: () async {
                                  await _apiService.patch('${ApiConstants.penalties}${p['id']}/', {'status': 'paid'});
                                  _fetchPenalties();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                  child: const Text('Mark Paid', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showIssuePenaltySheet,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Issue Penalty', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
