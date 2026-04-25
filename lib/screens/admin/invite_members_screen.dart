import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class InviteMembersScreen extends StatefulWidget {
  const InviteMembersScreen({super.key});

  @override
  State<InviteMembersScreen> createState() => _InviteMembersScreenState();
}

class _InviteMembersScreenState extends State<InviteMembersScreen> {
  final _wingController = TextEditingController();
  final _flatController = TextEditingController();
  final _mobileController = TextEditingController();

  void _sendInvite() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invite sent to ${_mobileController.text} for Flat ${_wingController.text}-${_flatController.text}'))
    );
    _wingController.clear();
    _flatController.clear();
    _mobileController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Residents')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text('Master Society QR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                  SizedBox(height: 16),
                  Icon(Icons.qr_code_2, size: 100, color: AppTheme.primaryDark),
                  SizedBox(height: 16),
                  Text('Society Code: ORX-9981', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  SizedBox(height: 8),
                  Text('Share this globally in your society.', textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Direct Manual Invite', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: CustomTextField(controller: _wingController, label: 'Wing', hint: 'e.g. A')),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: CustomTextField(controller: _flatController, label: 'Flat No.', hint: 'e.g. 101')),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(controller: _mobileController, label: 'Mobile Number', hint: '10-digit number', keyboardType: TextInputType.phone, prefixIcon: Icons.phone),
            const SizedBox(height: 24),
            CustomButton(text: 'Send Invite Link via WhatsApp', onPressed: _sendInvite),
          ],
        ),
      ),
    );
  }
}
