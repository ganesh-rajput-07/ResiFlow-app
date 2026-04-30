import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class JoinSocietyScreen extends StatefulWidget {
  const JoinSocietyScreen({super.key});

  @override
  State<JoinSocietyScreen> createState() => _JoinSocietyScreenState();
}

class _JoinSocietyScreenState extends State<JoinSocietyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _flatController = TextEditingController();
  final _personsController = TextEditingController(text: '1');
  final _familyDetailsController = TextEditingController();
  final _vehiclesController = TextEditingController(text: '0');
  final _parkingController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;

  Future<void> _submitJoinRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_codeController.text.isEmpty || _flatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Society Code and Flat Number'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.post(
        ApiConstants.submitJoinRequest,
        {
          'invite_code': _codeController.text.trim(),
          'requested_unit': _flatController.text.trim(),
          'family_members_count': int.tryParse(_personsController.text) ?? 1,
          'family_details': _familyDetailsController.text,
          'vehicles_count': int.tryParse(_vehiclesController.text) ?? 0,
          'parking_number': _parkingController.text,
        },
      );

      if (response.statusCode == 201 && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Request Sent!'),
              ],
            ),
            content: const Text(
              'Your request to join the society has been submitted.\n\n'
              'The admin will review your details and approve or reject it. '
              'You will be notified once a decision is made.',
            ),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back out of join screen
                },
              ),
            ],
          ),
        );
      } else if (mounted) {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['error'] ?? 'Failed to submit request'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('Scan Society QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan QR Code'),
                        onPressed: () {
                          // Future: QR scanner to auto-fill invite code
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryDark),
                      ),
                    ),
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
                label: 'Society Invite Code',
                hint: 'Enter Code (e.g., A1B2C3D4E5)',
                prefixIcon: Icons.business,
              ),
              const SizedBox(height: 24),
              const Text('Your Details', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _flatController,
                label: 'Flat/Unit Number',
                hint: 'Flat/Unit Number (e.g. A-101)',
                prefixIcon: Icons.door_front_door,
              ),
              const SizedBox(height: 24),
              const Text('Additional Information', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: CustomTextField(controller: _personsController, label: 'Family Members', hint: 'Count', keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: CustomTextField(controller: _vehiclesController, label: 'Vehicles', hint: 'Count', keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _parkingController,
                label: 'Parking Slot Number',
                hint: 'e.g. P-12, Basement B1',
                prefixIcon: Icons.local_parking,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _familyDetailsController,
                label: 'Family Details',
                hint: 'Names & Ages of members',
                prefixIcon: Icons.groups,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Submit Join Request',
                onPressed: _submitJoinRequest,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
