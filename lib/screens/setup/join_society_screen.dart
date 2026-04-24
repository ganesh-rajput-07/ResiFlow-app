import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../scanner/qr_scanner_screen.dart'; // We can use scanner to scan Society code

class JoinSocietyScreen extends StatefulWidget {
  const JoinSocietyScreen({super.key});

  @override
  State<JoinSocietyScreen> createState() => _JoinSocietyScreenState();
}

class _JoinSocietyScreenState extends State<JoinSocietyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _flatController = TextEditingController();

  bool _isLoading = false;

  void _submitJoinRequest() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    // TODO: Wire up to actual Registration/Join Request API
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
           context: context, 
           builder: (_) => AlertDialog(
              title: const Text('Request Sent'),
              content: const Text('Your request to join the society has been submitted for Admin approval.'),
              actions: [
                 TextButton(
                    child: const Text('OK'),
                    onPressed: () { 
                       Navigator.pop(context); // close dialog
                       Navigator.pop(context); // back out of join screen
                    }
                 )
              ]
           )
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(title: const Text('Join Society')),
       body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
             key: _formKey,
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                         color: AppTheme.primaryLight,
                         borderRadius: BorderRadius.circular(16)
                      ),
                      child: Column(
                         children: [
                            const Text('Scan Society QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            SizedBox(width: double.infinity, child: ElevatedButton.icon(
                               icon: const Icon(Icons.qr_code_scanner),
                               label: const Text('Scan QR Code'),
                               onPressed: () {
                                  // In real app, push QR Scanner setup for extracting string
                               },
                               style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryDark),
                            ))
                         ],
                      ),
                   ),
                   const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('OR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16))),
                   ),
                   const Text('Society Code', style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   CustomTextField(
                      controller: _codeController,
                      hint: 'Enter Code (e.g., ORX-1234)',
                      prefixIcon: Icons.business,
                   ),
                   const SizedBox(height: 24),
                   const Text('Your Details', style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   CustomTextField(
                      controller: _nameController,
                      hint: 'Full Name',
                      prefixIcon: Icons.person,
                   ),
                   const SizedBox(height: 16),
                   CustomTextField(
                      controller: _phoneController,
                      hint: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone,
                   ),
                   const SizedBox(height: 16),
                   CustomTextField(
                      controller: _flatController,
                      hint: 'Flat/Unit Number (e.g. A-101)',
                      prefixIcon: Icons.door_front_door,
                   ),
                   const SizedBox(height: 32),
                   CustomButton(
                      text: 'Submit Request',
                      onPressed: _submitJoinRequest,
                      isLoading: _isLoading,
                   )
                ],
             ),
          ),
       )
    );
  }
}
