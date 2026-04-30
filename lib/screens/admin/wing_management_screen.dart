import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class WingManagementScreen extends StatefulWidget {
  const WingManagementScreen({super.key});

  @override
  State<WingManagementScreen> createState() => _WingManagementScreenState();
}

class _WingManagementScreenState extends State<WingManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _wings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWings();
  }

  Future<void> _fetchWings() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.wingsList);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _wings = data is List ? data : (data['results'] ?? []));
      }
    } catch (e) {
      debugPrint('Error fetching wings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddWingSheet() {
    final nameController = TextEditingController();
    final floorsController = TextEditingController();
    final flatsController = TextEditingController();
    String numberFormat = 'floor_based';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create New Wing', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  CustomTextField(controller: nameController, label: 'Wing Name', hint: 'e.g. A, B, C', prefixIcon: Icons.apartment),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(controller: floorsController, label: 'Total Floors', hint: 'e.g. 10', keyboardType: TextInputType.number, prefixIcon: Icons.layers),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(controller: flatsController, label: 'Flats/Floor', hint: 'e.g. 4', keyboardType: TextInputType.number, prefixIcon: Icons.door_front_door),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Numbering Format', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _FormatOption(
                          title: 'Floor Based',
                          subtitle: '101, 102, 201...',
                          isSelected: numberFormat == 'floor_based',
                          onTap: () => setSheetState(() => numberFormat = 'floor_based'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FormatOption(
                          title: 'Sequential',
                          subtitle: '1, 2, 3, 4...',
                          isSelected: numberFormat == 'sequential',
                          onTap: () => setSheetState(() => numberFormat = 'sequential'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Create Wing & Generate Units',
                    onPressed: () async {
                      if (nameController.text.isEmpty || floorsController.text.isEmpty || flatsController.text.isEmpty) return;
                      final provider = Provider.of<AuthProvider>(ctx, listen: false);
                      final societyId = provider.user?['society'];
                      if (societyId == null) return;

                      final response = await _apiService.post(
                        ApiConstants.setupWing(societyId),
                        {
                          'name': nameController.text,
                          'total_floors': int.tryParse(floorsController.text) ?? 1,
                          'flats_per_floor': int.tryParse(flatsController.text) ?? 1,
                          'number_format': numberFormat,
                        },
                      );

                      if (response.statusCode == 201 && mounted) {
                        Navigator.pop(ctx);
                        _fetchWings();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Wing created with units!'), backgroundColor: Colors.green),
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
      appBar: AppBar(title: const Text('Wings & Units')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apartment, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No wings created yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Create your first wing to get started', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _wings.length,
                  itemBuilder: (context, index) {
                    final wing = _wings[index];
                    final units = wing['units'] as List? ?? [];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.apartment, color: AppTheme.primaryColor),
                        ),
                        title: Text('Wing ${wing['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${units.length} units • ${wing['number_format'] == 'floor_based' ? 'Floor Based' : 'Sequential'}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: units.map<Widget>((unit) {
                                final type = unit['unit_type'] ?? 'owner';
                                Color chipColor;
                                switch (type) {
                                  case 'rent': chipColor = Colors.blue; break;
                                  case 'closed': chipColor = Colors.grey; break;
                                  case 'dead': chipColor = Colors.red; break;
                                  case 'shop': chipColor = Colors.orange; break;
                                  default: chipColor = Colors.green;
                                }
                                return Chip(
                                  label: Text(unit['number'] ?? '?', style: TextStyle(color: chipColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                  backgroundColor: chipColor.withOpacity(0.1),
                                  side: BorderSide(color: chipColor.withOpacity(0.3)),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWingSheet,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Wing', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _FormatOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOption({required this.title, required this.subtitle, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : null,
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppTheme.primaryColor : null)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
