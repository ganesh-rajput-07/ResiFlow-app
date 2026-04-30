import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ManageGatekeepersScreen extends StatefulWidget {
  const ManageGatekeepersScreen({super.key});

  @override
  State<ManageGatekeepersScreen> createState() => _ManageGatekeepersScreenState();
}

class _ManageGatekeepersScreenState extends State<ManageGatekeepersScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _guards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGuards();
  }

  Future<void> _fetchGuards() async {
    setState(() => _isLoading = true);
    try {
      // Staff members of type 'watchman' serve as gatekeepers
      final response = await _apiService.get(ApiConstants.helpers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data is List ? data : (data['results'] ?? []);
        setState(() {
          _guards = results.where((s) => s['staff_type'] == 'watchman').toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching guards: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddGuardSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Gatekeeper', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CustomTextField(controller: nameController, label: 'Guard Name', hint: 'Full Name', prefixIcon: Icons.security),
              const SizedBox(height: 12),
              CustomTextField(controller: phoneController, label: 'Phone Number', hint: '10-digit mobile', keyboardType: TextInputType.phone, prefixIcon: Icons.phone),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Add Gatekeeper',
                onPressed: () async {
                  if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
                  final response = await _apiService.post(ApiConstants.helpers, {
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'staff_type': 'watchman',
                    'is_active': true,
                  });

                  if (response.statusCode == 201 && mounted) {
                    Navigator.pop(ctx);
                    _fetchGuards();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gatekeeper added!'), backgroundColor: Colors.green),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: ${response.body}'), backgroundColor: Colors.red),
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _toggleActive(dynamic guard) async {
    final response = await _apiService.patch(
      '${ApiConstants.helpers}${guard['id']}/',
      {'is_active': !(guard['is_active'] ?? true)},
    );
    if (response.statusCode == 200) _fetchGuards();
  }

  void _deleteGuard(dynamic guard) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Gatekeeper?'),
        content: Text('Are you sure you want to remove ${guard['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final response = await _apiService.delete('${ApiConstants.helpers}${guard['id']}/');
      if (response.statusCode == 204 && mounted) {
        _fetchGuards();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gatekeeper removed.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Gatekeepers')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _guards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No gatekeepers added yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _guards.length,
                  itemBuilder: (context, index) {
                    final guard = _guards[index];
                    final isActive = guard['is_active'] ?? true;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: isActive ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          child: Icon(Icons.security, color: isActive ? Colors.blue : Colors.grey),
                        ),
                        title: Text(guard['name'] ?? 'Guard', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('📞 ${guard['phone'] ?? 'N/A'}'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(isActive ? Icons.check_circle : Icons.cancel, size: 14, color: isActive ? Colors.green : Colors.red),
                                const SizedBox(width: 4),
                                Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isActive ? Colors.green : Colors.red)),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              onTap: () => _toggleActive(guard),
                              child: Text(isActive ? 'Deactivate' : 'Activate'),
                            ),
                            PopupMenuItem(
                              onTap: () => Future.delayed(Duration.zero, () => _deleteGuard(guard)),
                              child: const Text('Remove', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGuardSheet,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Guard', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
