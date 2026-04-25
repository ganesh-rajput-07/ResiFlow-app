import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class PenaltiesScreen extends StatefulWidget {
  const PenaltiesScreen({super.key});

  @override
  State<PenaltiesScreen> createState() => _PenaltiesScreenState();
}

class _PenaltiesScreenState extends State<PenaltiesScreen> {
  final _targetController = TextEditingController();
  final _reasonController = TextEditingController();
  final _amountController = TextEditingController();

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
              CustomButton(text: 'Issue Penalty', onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penalty issued successfully.')));
              }),
              const SizedBox(height: 32),
            ]
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Penalties')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 2,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.gavel, color: Colors.white)),
              title: Text('Flat A-${101 + index}'),
              subtitle: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text('Reason: Improper parking in guest slot.'),
                  SizedBox(height: 4),
                  Text('Status: UNPAID', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: const Text('₹500', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
