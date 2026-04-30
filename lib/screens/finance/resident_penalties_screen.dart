import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';

class ResidentPenaltiesScreen extends StatefulWidget {
  const ResidentPenaltiesScreen({super.key});

  @override
  State<ResidentPenaltiesScreen> createState() => _ResidentPenaltiesScreenState();
}

class _ResidentPenaltiesScreenState extends State<ResidentPenaltiesScreen> {
  final ApiService _apiService = ApiService();
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

  @override
  Widget build(BuildContext context) {
    final unpaid = _penalties.where((p) => p['status'] != 'paid').toList();
    final paid = _penalties.where((p) => p['status'] == 'paid').toList();
    final totalUnpaid = unpaid.fold<double>(0, (sum, p) => sum + (double.tryParse(p['amount']?.toString() ?? '0') ?? 0));

    return Scaffold(
      appBar: AppBar(title: const Text('My Penalties')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _penalties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                      const SizedBox(height: 16),
                      const Text('No penalties! 🎉', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('You\'re all clear.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Card
                      if (unpaid.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFEF5350)]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Unpaid Penalties', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('₹${totalUnpaid.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('${unpaid.length} pending ${unpaid.length == 1 ? 'penalty' : 'penalties'}', style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      if (unpaid.isNotEmpty) const SizedBox(height: 24),

                      // Unpaid
                      if (unpaid.isNotEmpty) ...[
                        const Text('Unpaid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...unpaid.map((p) => _buildPenaltyCard(p)),
                      ],

                      // Paid History
                      if (paid.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Cleared', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 12),
                        ...paid.map((p) => _buildPenaltyCard(p)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildPenaltyCard(dynamic p) {
    final isPaid = p['status'] == 'paid';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
            Text(p['reason'] ?? 'No reason specified'),
            const SizedBox(height: 4),
            Text(
              isPaid ? 'PAID ✓' : 'UNPAID',
              style: TextStyle(color: isPaid ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
