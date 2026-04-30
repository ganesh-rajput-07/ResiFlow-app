import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';

class HelpersDirectoryScreen extends StatefulWidget {
  const HelpersDirectoryScreen({super.key});

  @override
  State<HelpersDirectoryScreen> createState() => _HelpersDirectoryScreenState();
}

class _HelpersDirectoryScreenState extends State<HelpersDirectoryScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _helpers = [];
  bool _isLoading = true;

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
        setState(() => _helpers = results.where((h) => h['is_active'] == true).toList());
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getHelperIcon(String type) {
    switch (type) {
      case 'watchman': return Icons.security;
      case 'cleaner': return Icons.cleaning_services;
      case 'plumber': return Icons.plumbing;
      case 'electrician': return Icons.electrical_services;
      case 'liftman': return Icons.elevator;
      case 'manager': return Icons.person;
      default: return Icons.work;
    }
  }

  Color _getHelperColor(String type) {
    switch (type) {
      case 'watchman': return Colors.blue;
      case 'cleaner': return Colors.teal;
      case 'plumber': return Colors.orange;
      case 'electrician': return Colors.amber;
      case 'liftman': return Colors.purple;
      case 'manager': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group by type
    final grouped = <String, List<dynamic>>{};
    for (final h in _helpers) {
      final type = h['staff_type'] ?? 'other';
      grouped.putIfAbsent(type, () => []).add(h);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Society Helpers')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _helpers.isEmpty
              ? const Center(child: Text('No helpers registered yet.', style: TextStyle(color: Colors.grey)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: grouped.entries.map((entry) {
                    final type = entry.key;
                    final helpers = entry.value;
                    final color = _getHelperColor(type);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_getHelperIcon(type), size: 18, color: color),
                            const SizedBox(width: 8),
                            Text(
                              '${type[0].toUpperCase()}${type.substring(1)}s',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...helpers.map((h) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.1),
                              child: Icon(_getHelperIcon(type), color: color, size: 20),
                            ),
                            title: Text(h['name'] ?? 'Helper', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('📞 ${h['phone'] ?? 'N/A'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.phone, color: Colors.green),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Calling ${h['phone']}...')),
                                );
                              },
                            ),
                          ),
                        )),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}
