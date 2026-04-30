import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'package:intl/intl.dart';

class GenerateBillsScreen extends StatefulWidget {
  const GenerateBillsScreen({super.key});

  @override
  State<GenerateBillsScreen> createState() => _GenerateBillsScreenState();
}

class _GenerateBillsScreenState extends State<GenerateBillsScreen> {
  final ApiService _apiService = ApiService();
  final _titleController = TextEditingController(text: 'Maintenance - ${DateFormat('MMMM yyyy').format(DateTime.now())}');
  DateTime _dueDate = DateTime.now().copyWith(day: 28);
  bool _isGenerating = false;

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _generateBills() async {
    setState(() => _isGenerating = true);
    try {
      final response = await _apiService.post(
        ApiConstants.generateMonthlyBills,
        {
          'title': _titleController.text,
          'due_date': DateFormat('yyyy-MM-dd').format(_dueDate),
        },
      );

      if (response.statusCode == 201 && mounted) {
        final data = jsonDecode(response.body);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Bills Generated! 🎉'),
            content: Text('${data['count']} bills created successfully.\nAll units now have a pending maintenance bill.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back to finance hub
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['error'] ?? 'Failed to generate bills'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Monthly Bills')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.indigo),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will create a maintenance bill for every unit in your society using the default amount from Payment Settings.',
                      style: TextStyle(color: Colors.indigo, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CustomTextField(controller: _titleController, label: 'Bill Title', hint: 'Maintenance - April 2026', prefixIcon: Icons.receipt),
            const SizedBox(height: 24),
            const Text('Due Date', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDueDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('MMMM dd, yyyy').format(_dueDate), style: const TextStyle(fontSize: 16)),
                    const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            CustomButton(
              text: 'Generate Bills for All Units',
              onPressed: _generateBills,
              isLoading: _isGenerating,
            ),
          ],
        ),
      ),
    );
  }
}
