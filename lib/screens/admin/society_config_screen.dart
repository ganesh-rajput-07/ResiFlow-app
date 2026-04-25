import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class SocietyConfigScreen extends StatefulWidget {
  const SocietyConfigScreen({super.key});

  @override
  State<SocietyConfigScreen> createState() => _SocietyConfigScreenState();
}

class _SocietyConfigScreenState extends State<SocietyConfigScreen> {
  final _amountController = TextEditingController(text: '1500');
  final _bankAccountController = TextEditingController(text: '0987654321234');
  final _ifscController = TextEditingController(text: 'HDFC0001234');
  
  final _guardNameController = TextEditingController();
  final _guardPhoneController = TextEditingController();

  final _wingFormatController = TextEditingController(text: '101, 102, 103');
  
  bool _onlinePayments = true;
  bool _cashPayments = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Society Configuration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Maintenance & Finance'),
            const SizedBox(height: 16),
            CustomTextField(controller: _amountController, label: 'Default Maintenance (₹)', hint: 'Amount', prefixIcon: Icons.currency_rupee, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            CustomTextField(controller: _bankAccountController, label: 'Society Bank Account No.', hint: 'Account No', prefixIcon: Icons.account_balance),
            const SizedBox(height: 12),
            CustomTextField(controller: _ifscController, label: 'IFSC Code', hint: 'IFSC', prefixIcon: Icons.account_balance_wallet),
            SwitchListTile(
              title: const Text('Online Payments Enabled'),
              value: _onlinePayments,
              activeColor: AppTheme.primaryColor,
              onChanged: (v) => setState(() => _onlinePayments = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Cash Payments Enabled'),
              value: _cashPayments,
              activeColor: AppTheme.primaryColor,
              onChanged: (v) => setState(() => _cashPayments = v),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 48),

            _buildSectionHeader('Manage Gatekeepers'),
            const SizedBox(height: 16),
            CustomTextField(controller: _guardNameController, label: 'Guard Name', hint: 'Name', prefixIcon: Icons.security),
            const SizedBox(height: 12),
            CustomTextField(controller: _guardPhoneController, label: 'Guard Phone', hint: 'Mobile', prefixIcon: Icons.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Gatekeeper'),
              ),
            ),
            const Divider(height: 48),

            _buildSectionHeader('Wing & Naming Conventions'),
            const SizedBox(height: 16),
            CustomTextField(controller: _wingFormatController, label: 'Flat Naming Convention', hint: 'e.g. 101, 102 OR G1, G2', prefixIcon: Icons.format_list_numbered),
            
            const SizedBox(height: 48),
            CustomButton(text: 'Save Configuration', onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuration saved successfully!')));
               Navigator.pop(context);
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
    );
  }
}
