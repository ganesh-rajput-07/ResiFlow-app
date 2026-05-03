import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RequestRenterScreen extends StatefulWidget {
  const RequestRenterScreen({super.key});

  @override
  State<RequestRenterScreen> createState() => _RequestRenterScreenState();
}

class _RequestRenterScreenState extends State<RequestRenterScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  List<dynamic> _myUnits = [];
  dynamic _selectedUnit;
  bool _isLoadingUnits = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchMyUnits();
  }

  Future<void> _fetchMyUnits() async {
    setState(() => _isLoadingUnits = true);
    try {
      final user = context.read<AuthProvider>().user;
      final response = await _apiService.get(ApiConstants.profile);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List residentUnits = data['resident_units'] ?? [];
        // Only show units where the user is an owner
        setState(() {
          _myUnits = residentUnits.where((u) => u['role'] == 'owner').toList();
          if (_myUnits.isNotEmpty) {
            _selectedUnit = _myUnits[0];
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching units: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUnits = false);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() || _selectedUnit == null) {
      if (_selectedUnit == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a unit')));
      }
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final payload = {
        'unit': _selectedUnit['unit'],
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
      };

      final response = await _apiService.post(ApiConstants.renterRequests, payload);
      if (response.statusCode == 201 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Renter request submitted to admin!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        final err = jsonDecode(response.body)['error'] ?? 'Submission failed';
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Renter Account')),
      body: _isLoadingUnits 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Renter Account Request', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Select your flat and provide renter details to request an account.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  
                  // Unit Dropdown
                  const Text('Select Your Flat', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<dynamic>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      prefixIcon: Icon(Icons.apartment),
                    ),
                    items: _myUnits.map((u) => DropdownMenuItem(
                      value: u,
                      child: Text('Unit ${u['unit_number']} (${u['wing_name']})'),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedUnit = val),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('Renter Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: CustomTextField(controller: _firstNameController, label: 'First Name', hint: 'John')),
                      const SizedBox(width: 12),
                      Expanded(child: CustomTextField(controller: _lastNameController, label: 'Last Name', hint: 'Doe')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _phoneController, label: 'Mobile Number', hint: '9876543210', prefixIcon: Icons.phone, keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _emailController, label: 'Email (Optional)', hint: 'john@example.com', prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  
                  const SizedBox(height: 24),
                  const Text('Login Credentials', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  CustomTextField(controller: _usernameController, label: 'Username', hint: 'johndoe_rent', prefixIcon: Icons.alternate_email),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _passwordController, label: 'Password', hint: '••••••••', obscureText: true, prefixIcon: Icons.lock_outline),
                  
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Submit Request',
                    isLoading: _isSubmitting,
                    onPressed: _submitRequest,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }
}
