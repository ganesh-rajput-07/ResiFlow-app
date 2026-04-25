import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ManageHelpersScreen extends StatefulWidget {
  const ManageHelpersScreen({super.key});

  @override
  State<ManageHelpersScreen> createState() => _ManageHelpersScreenState();
}

class _ManageHelpersScreenState extends State<ManageHelpersScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _typeController = TextEditingController();

  void _showAddHelperSheet() {
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
              const Text('Register Helper/Staff', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CustomTextField(controller: _nameController, label: 'Full Name', hint: 'Helper Name', prefixIcon: Icons.person),
              const SizedBox(height: 12),
              CustomTextField(controller: _phoneController, label: 'Phone Number', hint: '10-digit mobile', prefixIcon: Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              CustomTextField(controller: _typeController, label: 'Helper Type', hint: 'Maid, Cook, Driver, Electrician...'),
              const SizedBox(height: 24),
              CustomButton(text: 'Register Helper', onPressed: () {
                _nameController.clear();
                _phoneController.clear();
                _typeController.clear();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Helper Profile Created!')));
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
      appBar: AppBar(title: const Text('House Keepers & Staff')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 2,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(backgroundColor: AppTheme.primaryLight, child: Icon(Icons.cleaning_services, color: AppTheme.primaryDark)),
              title: Text('Sita Devi ${index+1}'),
              subtitle: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text('Role: Maid • Phone: 9876543210'),
                  SizedBox(height: 4),
                  Row(
                    children: [
                       Icon(Icons.check_circle, size: 14, color: Colors.green),
                       SizedBox(width: 4),
                       Text('Active Pass', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  )
                ],
              ),
              trailing: IconButton(
                 icon: const Icon(Icons.qr_code, color: AppTheme.primaryColor),
                 onPressed: () {
                    // Logic to show QR for the helper to scan at the gate
                 },
              )
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHelperSheet,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Helper', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
