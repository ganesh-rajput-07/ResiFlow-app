import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ManageHelpersScreen extends StatefulWidget {
  const ManageHelpersScreen({super.key});

  @override
  State<ManageHelpersScreen> createState() => _ManageHelpersScreenState();
}

class _ManageHelpersScreenState extends State<ManageHelpersScreen> {
  final ApiService _apiService = ApiService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  List<dynamic> _helpers = [];
  bool _isLoading = true;
  String _selectedType = 'cleaner';

  final _staffTypes = ['watchman', 'liftman', 'cleaner', 'plumber', 'electrician', 'manager', 'other'];

  @override
  void initState() {
    super.initState();
    _fetchHelpers();
  }

  Future<void> _fetchHelpers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.helpers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data is List ? data : (data['results'] ?? []);
        // Show helpers (exclude watchman which are managed in Gatekeepers screen)
        setState(() => _helpers = results.where((s) => s['staff_type'] != 'watchman').toList());
      }
    } catch (e) {
      debugPrint('Error fetching helpers: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddHelperSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
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
                  const Text('Helper Type', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _staffTypes.where((t) => t != 'watchman').map((type) {
                      final isSelected = _selectedType == type;
                      return ChoiceChip(
                        label: Text(type[0].toUpperCase() + type.substring(1)),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        onSelected: (_) => setSheetState(() => _selectedType = type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Register Helper',
                    onPressed: () async {
                      if (_nameController.text.isEmpty || _phoneController.text.isEmpty) return;
                      final response = await _apiService.post(ApiConstants.helpers, {
                        'name': _nameController.text,
                        'phone': _phoneController.text,
                        'staff_type': _selectedType,
                        'is_active': true,
                      });

                      if (response.statusCode == 201 && mounted) {
                        _nameController.clear();
                        _phoneController.clear();
                        Navigator.pop(ctx);
                        _fetchHelpers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Helper registered!'), backgroundColor: Colors.green),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('House Keepers & Staff')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _helpers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cleaning_services, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No helpers registered yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _helpers.length,
                  itemBuilder: (context, index) {
                    final helper = _helpers[index];
                    final isActive = helper['is_active'] ?? true;
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryLight,
                          child: const Icon(Icons.cleaning_services, color: AppTheme.primaryDark),
                        ),
                        title: Text(helper['name'] ?? 'Helper', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Role: ${helper['staff_type'] ?? 'N/A'} • 📞 ${helper['phone'] ?? 'N/A'}'),
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
                              onTap: () async {
                                await _apiService.patch('${ApiConstants.helpers}${helper['id']}/', {'is_active': !isActive});
                                _fetchHelpers();
                              },
                              child: Text(isActive ? 'Deactivate' : 'Activate'),
                            ),
                            PopupMenuItem(
                              onTap: () async {
                                await _apiService.delete('${ApiConstants.helpers}${helper['id']}/');
                                _fetchHelpers();
                              },
                              child: const Text('Remove', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
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
