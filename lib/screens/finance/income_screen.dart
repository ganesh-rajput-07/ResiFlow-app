import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _records = [];
  bool _isLoading = true;

  static const _categories = {
    'maintenance': ('Maintenance', Icons.home, Colors.blue),
    'penalty_collection': ('Penalty', Icons.gavel, Colors.orange),
    'parking_rent': ('Parking Rent', Icons.local_parking, Colors.indigo),
    'hall_booking': ('Hall Booking', Icons.meeting_room, Colors.purple),
    'interest': ('Bank Interest', Icons.account_balance, Colors.teal),
    'deposit': ('Deposit / Corpus', Icons.savings, Colors.green),
    'other': ('Other', Icons.more_horiz, Colors.grey),
  };

  @override
  void initState() {
    super.initState();
    _fetchIncome();
  }

  Future<void> _fetchIncome() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.income);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _records = data is List ? data : List.from(data['results'] ?? []));
      }
    } catch (e) {
      debugPrint('Error fetching income: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddIncomeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: _AddIncomeForm(
            onSuccess: () {
              Navigator.pop(ctx);
              _fetchIncome();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Income recorded.'), backgroundColor: Colors.green),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Society Income')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(child: Text('No income recorded yet.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final r = _records[index];
                    final cat = r['category'] ?? 'other';
                    final catInfo = _categories[cat] ?? ('Other', Icons.more_horiz, Colors.grey);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: catInfo.$3.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(catInfo.$2, color: catInfo.$3, size: 24),
                        ),
                        title: Text(r['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(catInfo.$1, style: TextStyle(color: catInfo.$3, fontSize: 12, fontWeight: FontWeight.w600)),
                            if (r['income_date'] != null)
                              Text(r['income_date'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        trailing: Text(
                          '₹${r['amount']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddIncomeSheet,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Income', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Income Form
// ---------------------------------------------------------------------------
class _AddIncomeForm extends StatefulWidget {
  final VoidCallback onSuccess;
  const _AddIncomeForm({required this.onSuccess});

  @override
  State<_AddIncomeForm> createState() => _AddIncomeFormState();
}

class _AddIncomeFormState extends State<_AddIncomeForm> {
  final ApiService _apiService = ApiService();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'other';
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  static const _categoryOptions = [
    ('maintenance', 'Maintenance Collection'),
    ('penalty_collection', 'Penalty Collection'),
    ('parking_rent', 'Parking Rent'),
    ('hall_booking', 'Hall Booking'),
    ('interest', 'Bank Interest'),
    ('deposit', 'Deposit / Corpus'),
    ('other', 'Other Income'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Record Income', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(controller: _titleController, label: 'Title', hint: 'e.g. Hall Booking - Sharma Family'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            items: _categoryOptions.map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2))).toList(),
            onChanged: (val) => setState(() => _selectedCategory = val ?? 'other'),
          ),
          const SizedBox(height: 12),
          CustomTextField(controller: _amountController, label: 'Amount (₹)', hint: '10000', keyboardType: TextInputType.number, prefixIcon: Icons.currency_rupee),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Income Date',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
            ),
          ),
          const SizedBox(height: 12),
          CustomTextField(controller: _descController, label: 'Description (optional)', hint: 'Any notes...'),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Save Income',
            isLoading: _isSubmitting,
            onPressed: () async {
              if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill title and amount')));
                return;
              }
              setState(() => _isSubmitting = true);
              final response = await _apiService.post(ApiConstants.income, {
                'title': _titleController.text,
                'category': _selectedCategory,
                'amount': _amountController.text,
                'income_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
                'description': _descController.text,
              });
              if (response.statusCode == 201 && mounted) {
                widget.onSuccess();
              } else if (mounted) {
                setState(() => _isSubmitting = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${response.body}'), backgroundColor: Colors.red));
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
