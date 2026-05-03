import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/rent_badge.dart';

class SocietyDirectoryScreen extends StatefulWidget {
  const SocietyDirectoryScreen({super.key});

  @override
  State<SocietyDirectoryScreen> createState() => _SocietyDirectoryScreenState();
}

class _SocietyDirectoryScreenState extends State<SocietyDirectoryScreen> {
  final ApiService _apiService = ApiService();
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _members = [];

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers([String query = '']) async {
    setState(() => _isLoading = true);
    try {
      final url = query.isEmpty ? ApiConstants.societyDirectory : '${ApiConstants.societyDirectory}?search=$query';
      final response = await _apiService.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _members = data is List ? data : (data['results'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Society Directory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Name, Vehicle, or Unit...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _fetchMembers(_searchController.text),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: _fetchMembers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _members.isEmpty
                    ? const Center(child: Text('No members found matching your search.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final m = _members[index];
                          final vehicles = m['vehicles'] as List? ?? [];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppTheme.primaryLight,
                                        child: Text(m['first_name'][0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text('${m['first_name']} ${m['last_name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                const SizedBox(width: 8),
                                                RentBadge(isRenter: m['is_renter'] ?? false),
                                              ],
                                            ),
                                            Text('Unit: ${m['unit_number'] ?? 'Not Assigned'} • ${m['role'].toString().toUpperCase()}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.phone, color: Colors.green),
                                        onPressed: () {
                                          // TODO: Implement phone call
                                        },
                                      ),
                                    ],
                                  ),
                                  if (vehicles.isNotEmpty) ...[
                                    const Divider(height: 24),
                                    const Text('Vehicles:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: vehicles.map((v) => Chip(
                                        avatar: Icon(v['vehicle_type'] == '4_wheeler' ? Icons.directions_car : Icons.directions_bike, size: 16, color: AppTheme.primaryDark),
                                        label: Text(v['vehicle_number'], style: const TextStyle(fontSize: 11)),
                                        backgroundColor: AppTheme.primaryLight.withOpacity(0.5),
                                      )).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
