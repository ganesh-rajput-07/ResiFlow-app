import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreateSocietyScreen extends StatefulWidget {
  const CreateSocietyScreen({super.key});

  @override
  State<CreateSocietyScreen> createState() => _CreateSocietyScreenState();
}

class _CreateSocietyScreenState extends State<CreateSocietyScreen> {
  int _currentStep = 0;
  
  // Step 1: Basic Info
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  // Step 2: Payment
  final _maintenanceController = TextEditingController();
  bool _cashEnabled = true;
  bool _onlineEnabled = true;

  // Step 3: Gatekeeper
  final _guardNameController = TextEditingController();
  final _guardPhoneController = TextEditingController();
  String _guardShift = 'Day';

  void _finishSetup() {
    // TODO: Wire to Real backend setup procedure
    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        title: const Text('Setup Complete!'),
        content: const Text('Your society has been created successfully. Welcome Admin!'),
        actions: [
           TextButton(
             onPressed: () {
               Navigator.of(context).popUntil((route) => route.isFirst);
             }, 
             child: const Text('Go to Login')
           )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
        appBar: AppBar(title: const Text('Create Society')),
        body: Stepper(
           currentStep: _currentStep,
           onStepContinue: () {
              if (_currentStep < 3) {
                 setState(() => _currentStep += 1);
              } else {
                 _finishSetup();
              }
           },
           onStepCancel: () {
              if (_currentStep > 0) {
                 setState(() => _currentStep -= 1);
              } else {
                 Navigator.of(context).pop();
              }
           },
           controlsBuilder: (context, details) {
              return Padding(
                 padding: const EdgeInsets.only(top: 24),
                 child: Row(
                    children: [
                       Expanded(
                          child: CustomButton(
                             text: _currentStep == 3 ? 'Finish Setup' : 'Continue',
                             onPressed: details.onStepContinue ?? () {},
                          )
                       ),
                       if (_currentStep > 0)
                          Padding(
                             padding: const EdgeInsets.only(left: 16),
                             child: TextButton(
                                onPressed: details.onStepCancel,
                                child: const Text('Back', style: TextStyle(color: Colors.grey)),
                             ),
                          )
                    ],
                 )
              );
           },
           steps: [
              Step(
                 title: const Text('Basic Information'),
                 isActive: _currentStep >= 0,
                 state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                 content: Column(
                    children: [
                       CustomTextField(controller: _nameController, label: 'Society Name', hint: 'Society Name', prefixIcon: Icons.business),
                       const SizedBox(height: 16),
                       CustomTextField(controller: _addressController, label: 'Address', hint: 'Address', prefixIcon: Icons.map),
                       const SizedBox(height: 16),
                       Row(
                         children: [
                           Expanded(child: CustomTextField(controller: _cityController, label: 'City', hint: 'City')),
                           const SizedBox(width: 16),
                           Expanded(child: CustomTextField(controller: _stateController, label: 'State', hint: 'State')),
                         ],
                       ),
                       const SizedBox(height: 16),
                       CustomTextField(controller: _pincodeController, label: 'Pincode', hint: 'e.g. 400001', keyboardType: TextInputType.number, prefixIcon: Icons.pin_drop),
                    ]
                 )
              ),
              Step(
                 title: const Text('Payment Config'),
                 isActive: _currentStep >= 1,
                 state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                 content: Column(
                    children: [
                       CustomTextField(controller: _maintenanceController, label: 'Maintenance Amount', hint: 'Maintenance Amount', prefixIcon: Icons.currency_rupee, keyboardType: TextInputType.number),
                       SwitchListTile(
                          title: const Text('Allow Cash Payments'),
                          value: _cashEnabled,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (val) => setState(() => _cashEnabled = val)
                       ),
                       SwitchListTile(
                          title: const Text('Allow Online Payments'),
                          value: _onlineEnabled,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (val) => setState(() => _onlineEnabled = val)
                       ),
                    ]
                 )
              ),
              Step(
                 title: const Text('Gatekeeper Setup'),
                 isActive: _currentStep >= 2,
                 state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                 content: Column(
                    children: [
                       CustomTextField(controller: _guardNameController, label: 'Guard Name', hint: 'Guard Name', prefixIcon: Icons.security),
                       const SizedBox(height: 16),
                       CustomTextField(controller: _guardPhoneController, label: 'Guard Phone', hint: 'Guard Phone', prefixIcon: Icons.phone_android, keyboardType: TextInputType.phone),
                       const SizedBox(height: 16),
                       DropdownButtonFormField<String>(
                         value: _guardShift,
                         decoration: InputDecoration(
                           labelText: 'Guard Shift',
                           prefixIcon: const Icon(Icons.access_time),
                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                         items: ['Day', 'Night', '24x7'].map((String value) {
                           return DropdownMenuItem<String>(
                             value: value,
                             child: Text(value),
                           );
                         }).toList(),
                         onChanged: (val) => setState(() => _guardShift = val!),
                       )
                    ]
                 )
              ),
              Step(
                 title: const Text('Member Invite'),
                 isActive: _currentStep >= 3,
                 content: Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                       color: AppTheme.primaryLight,
                       borderRadius: BorderRadius.circular(16)
                    ),
                    child: const Column(
                       children: [
                          Icon(Icons.qr_code_2, size: 80, color: AppTheme.primaryDark),
                          SizedBox(height: 16),
                          Text('Society Code: ORX-9981', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                          SizedBox(height: 8),
                          Text('Share this code with your residents or let them scan the QR to join.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textDark)),
                       ]
                    )
                 )
              )
           ]
        )
     );
  }
}
