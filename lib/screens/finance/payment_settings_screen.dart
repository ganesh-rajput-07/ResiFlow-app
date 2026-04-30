import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final ApiService _apiService = ApiService();
  final _amountController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();

  bool _cashEnabled = true;
  bool _onlineEnabled = false;
  bool _upiEnabled = false;
  bool _isLoading = true;
  bool _isSaving = false;
  int? _settingsId;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.paymentSettings);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data is List ? data : (data['results'] ?? []);
        if (results.isNotEmpty) {
          final s = results[0];
          _settingsId = s['id'];
          _amountController.text = (s['default_maintenance_amount'] ?? '0').toString();
          _bankAccountController.text = s['bank_account_number'] ?? '';
          _ifscController.text = s['bank_ifsc'] ?? '';
          _cashEnabled = s['cash'] ?? true;
          _onlineEnabled = s['upload_receipt'] ?? false;
          // UPI is tracked via the upi field we check
          _upiEnabled = (s['easebuzz'] ?? false); // repurpose for UPI toggle
        }
      }
    } catch (e) {
      debugPrint('Error fetching payment settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final body = {
        'default_maintenance_amount': _amountController.text,
        'bank_account_number': _bankAccountController.text,
        'bank_ifsc': _ifscController.text,
        'cash': _cashEnabled,
        'upload_receipt': _onlineEnabled,
        'easebuzz': _upiEnabled,
      };

      final response = _settingsId != null
          ? await _apiService.put('${ApiConstants.paymentSettings}$_settingsId/', body)
          : await _apiService.post(ApiConstants.paymentSettings, body);

      if ((response.statusCode == 200 || response.statusCode == 201) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment settings saved!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${response.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Default Maintenance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _amountController,
                    label: 'Monthly Amount (₹)',
                    hint: '1500',
                    prefixIcon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  const Text('Bank Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                  const SizedBox(height: 16),
                  CustomTextField(controller: _bankAccountController, label: 'Bank Account Number', hint: 'Account No', prefixIcon: Icons.account_balance),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _ifscController, label: 'IFSC Code', hint: 'HDFC0001234', prefixIcon: Icons.account_balance_wallet),
                  const SizedBox(height: 24),
                  const Text('UPI Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                  const SizedBox(height: 16),
                  CustomTextField(controller: _upiController, label: 'UPI ID (for residents to pay)', hint: 'society@upi', prefixIcon: Icons.qr_code),
                  const SizedBox(height: 24),
                  const Text('Payment Modes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                  SwitchListTile(
                    title: const Text('Cash Payments'),
                    subtitle: const Text('Allow offline cash collection'),
                    value: _cashEnabled,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => setState(() => _cashEnabled = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Online / Receipt Upload'),
                    subtitle: const Text('Let residents upload payment receipt'),
                    value: _onlineEnabled,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => setState(() => _onlineEnabled = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('UPI Payments'),
                    subtitle: const Text('Generate UPI payment links'),
                    value: _upiEnabled,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => setState(() => _upiEnabled = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Save Settings',
                    onPressed: _saveSettings,
                    isLoading: _isSaving,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
