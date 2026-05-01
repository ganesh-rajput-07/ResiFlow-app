import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ManageGuardsScreen extends StatefulWidget {
  const ManageGuardsScreen({super.key});

  @override
  State<ManageGuardsScreen> createState() => _ManageGuardsScreenState();
}

class _ManageGuardsScreenState extends State<ManageGuardsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _guards = [];

  @override
  void initState() {
    super.initState();
    _fetchGuards();
  }

  Future<void> _fetchGuards() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.manageGuards);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _guards = data is List ? data : (data['results'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetching guards: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddGuardDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddGuardDialog(onSuccess: _fetchGuards),
    );
  }

  Future<void> _deleteGuard(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to remove this guard?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _apiService.delete('${ApiConstants.manageGuards}$id/');
        if (response.statusCode == 204) {
          _fetchGuards();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guard removed')));
        }
      } catch (e) {
        debugPrint('Error deleting guard: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Society Guards')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _guards.isEmpty
              ? const Center(child: Text('No guards registered yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _guards.length,
                  itemBuilder: (context, index) {
                    final guard = _guards[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryLight,
                          child: const Icon(Icons.security, color: AppTheme.primaryColor),
                        ),
                        title: Text(guard['full_name'] ?? guard['username'] ?? 'Guard', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Phone: ${guard['phone'] ?? 'N/A'}\nUsername: ${guard['username']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteGuard(guard['id']),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGuardDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Guard'),
        backgroundColor: AppTheme.primaryDark,
      ),
    );
  }
}

class _AddGuardDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const _AddGuardDialog({required this.onSuccess});

  @override
  State<_AddGuardDialog> createState() => _AddGuardDialogState();
}

class _AddGuardDialogState extends State<_AddGuardDialog> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _apiService = ApiService();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Guard Account'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(controller: _usernameController, label: 'Username', hint: 'guard_123'),
            const SizedBox(height: 12),
            CustomTextField(controller: _passwordController, label: 'Password', hint: '••••••••', obscureText: true),
            const SizedBox(height: 12),
            CustomTextField(controller: _nameController, label: 'Full Name', hint: 'John Doe'),
            const SizedBox(height: 12),
            CustomTextField(controller: _phoneController, label: 'Phone Number', hint: '1234567890'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        SizedBox(
          width: 100,
          child: CustomButton(
            text: 'Create',
            isLoading: _isSubmitting,
            onPressed: () async {
              if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
                return;
              }
              setState(() => _isSubmitting = true);
              try {
                final response = await _apiService.post(ApiConstants.manageGuards, {
                  'username': _usernameController.text,
                  'password': _passwordController.text,
                  'first_name': _nameController.text.split(' ').first,
                  'last_name': _nameController.text.contains(' ') ? _nameController.text.split(' ').sublist(1).join(' ') : '',
                  'phone': _phoneController.text,
                });

                if (response.statusCode == 201) {
                  widget.onSuccess();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guard account created')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
                }
              } catch (e) {
                debugPrint('Error: $e');
              } finally {
                setState(() => _isSubmitting = false);
              }
            },
          ),
        ),
      ],
    );
  }
}
