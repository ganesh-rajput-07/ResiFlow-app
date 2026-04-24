import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../models/pre_approval.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class PreApprovalScreen extends StatefulWidget {
  const PreApprovalScreen({super.key});

  @override
  State<PreApprovalScreen> createState() => _PreApprovalScreenState();
}

class _PreApprovalScreenState extends State<PreApprovalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _purposeController = TextEditingController();
  final _personsController = TextEditingController(text: '1');
  
  DateTime _validFrom = DateTime.now();
  DateTime _validTo = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _validFrom : _validTo,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _validFrom = picked;
          if (_validTo.isBefore(_validFrom)) {
            _validTo = _validFrom.add(const Duration(days: 1));
          }
        } else {
          _validTo = picked;
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final req = PreApproval(
        visitorName: _nameController.text,
        mobile: _phoneController.text,
        purpose: _purposeController.text,
        numberOfPersons: int.tryParse(_personsController.text) ?? 1,
        validFrom: DateFormat('yyyy-MM-dd').format(_validFrom),
        validTo: DateFormat('yyyy-MM-dd').format(_validTo),
      );

      final response = await _apiService.post(
        ApiConstants.preApprovals,
        req.toJson(),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pre-approval request submitted successfully!')),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Pre-Approval'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Pre-Approval',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                label: 'Visitor Name',
                hint: 'Enter full name',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '10-digit mobile number',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 32),
              const Text(
                'Visit Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                    child: _buildDateSelector('Valid From', _validFrom, () => _selectDate(context, true)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateSelector('Valid To', _validTo, () => _selectDate(context, false)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _purposeController,
                      label: 'Purpose',
                      hint: 'e.g. Guest, Delivery',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: CustomTextField(
                      controller: _personsController,
                      label: 'Persons',
                      hint: '1',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              CustomButton(
                text: 'Submit Request',
                onPressed: _submitRequest,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('MMM dd, yyyy').format(date)),
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
