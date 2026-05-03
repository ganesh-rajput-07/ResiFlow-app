import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';

class RentingDetailsScreen extends StatefulWidget {
  const RentingDetailsScreen({super.key});

  @override
  State<RentingDetailsScreen> createState() => _RentingDetailsScreenState();
}

class _RentingDetailsScreenState extends State<RentingDetailsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _units = [];

  @override
  void initState() {
    super.initState();
    _fetchRentingDetails();
  }

  Future<void> _fetchRentingDetails() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.profile);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List residentUnits = data['resident_units'] ?? [];
        
        // For each unit, if the user is an owner, fetch the unit details to see tenants
        List detailedUnits = [];
        for (var ru in residentUnits) {
          if (ru['role'] == 'owner') {
            final unitRes = await _apiService.get('${ApiConstants.unitsList}${ru['unit']}/');
            if (unitRes.statusCode == 200) {
              detailedUnits.add(jsonDecode(unitRes.body));
            } else {
              detailedUnits.add(ru);
            }
          } else {
            detailedUnits.add(ru);
          }
        }

        setState(() {
          _units = detailedUnits;
        });
      }
    } catch (e) {
      debugPrint('Error fetching renting details: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renting & Units'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _units.isEmpty
              ? const Center(child: Text('No units assigned to you.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _units.length,
                  itemBuilder: (context, index) {
                    final u = _units[index];
                    final bool isDetailed = u.containsKey('residents');
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildUnitHeader(u),
                          const Divider(height: 1),
                          if (isDetailed) ...[
                            _buildTenantSection(u),
                          ] else ...[
                            _buildRoleSection(u),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildUnitHeader(dynamic u) {
    String unitNum = u['number'] ?? u['unit_number'] ?? 'N/A';
    String wingName = u['wing_name'] ?? (u['wing'] != null ? u['wing'].toString() : 'N/A');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.apartment, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Unit $unitNum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Wing $wingName', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ],
          ),
          const Spacer(),
          _buildRoleChip(u['role'] ?? 'owner'),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    Color color;
    switch (role.toLowerCase()) {
      case 'owner': color = Colors.blue; break;
      case 'tenant': color = Colors.orange; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTenantSection(dynamic u) {
    final residents = List.from(u['residents'] ?? []);
    final tenants = residents.where((r) => r['role'] == 'tenant').toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TENANT DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          if (tenants.isEmpty)
            const Text('No active tenant for this unit.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
          else
            ...tenants.map((t) => _buildResidentTile(t)),
        ],
      ),
    );
  }

  Widget _buildRoleSection(dynamic ru) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OCCUPANCY DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today, 'Started', ru['agreement_start_date'] ?? 'N/A'),
          if (ru['role'] == 'tenant') ...[
            _buildInfoRow(Icons.event_available, 'Ends', ru['agreement_end_date'] ?? 'N/A'),
            _buildInfoRow(Icons.currency_rupee, 'Rent', '₹${ru['rent_amount'] ?? '0'}'),
          ],
        ],
      ),
    );
  }

  Widget _buildResidentTile(dynamic res) {
    final ud = res['user_details'] ?? {};
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange.withOpacity(0.1),
            child: const Icon(Icons.person, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${ud['first_name'] ?? ''} ${ud['last_name'] ?? ''}'.trim(), style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(ud['phone'] ?? 'No phone', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.green, size: 20),
            onPressed: () {
              // TODO: Launch dialer
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
