import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';

class ManageResidentsScreen extends StatefulWidget {
  const ManageResidentsScreen({super.key});

  @override
  State<ManageResidentsScreen> createState() => _ManageResidentsScreenState();
}

class _ManageResidentsScreenState extends State<ManageResidentsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _residents = [];
  List<dynamic> _units = [];
  List<dynamic> _parkingLots = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _apiService.get(ApiConstants.manageResidents),
        _apiService.get(ApiConstants.unitsList),
        _apiService.get(ApiConstants.parkingLots),
      ]);

      if (mounted) {
        setState(() {
          final resData = jsonDecode(futures[0].body);
          _residents = resData is List ? List.from(resData) : List.from(resData['results'] ?? []);
          
          final unitsData = jsonDecode(futures[1].body);
          _units = unitsData is List ? List.from(unitsData) : List.from(unitsData['results'] ?? []);
          
          final parkingData = jsonDecode(futures[2].body);
          _parkingLots = parkingData is List ? List.from(parkingData) : List.from(parkingData['results'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetching residents data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditDialog(dynamic resident) {
    int? selectedUnitId = resident['unit'];
    
    // Find current parking lot for this tenant
    dynamic currentParking;
    try {
      currentParking = _parkingLots.firstWhere((p) => p['tenant'] == resident['id']);
    } catch (_) {}
    
    int? selectedParkingId = currentParking != null ? currentParking['id'] : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manage Resident', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${resident['first_name']} ${resident['last_name']}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 24),
                  
                  DropdownButtonFormField<int>(
                    value: selectedUnitId,
                    decoration: const InputDecoration(labelText: 'Assigned Flat', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                    items: _units.map((u) => DropdownMenuItem<int>(value: u['id'], child: Text('${u['wing_name']}-${u['number']}', style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (val) => setModalState(() => selectedUnitId = val),
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<int?>(
                    value: selectedParkingId,
                    decoration: const InputDecoration(labelText: 'Assigned Parking Lot', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('None')),
                      ..._parkingLots.map((p) => DropdownMenuItem<int?>(value: p['id'], child: Text('Lot ${p['lot_number']} (${p['status']})'))),
                    ],
                    onChanged: (val) => setModalState(() => selectedParkingId = val),
                  ),
                  const SizedBox(height: 32),
                  
                  CustomButton(
                    text: 'Save Changes',
                    onPressed: () async {
                      try {
                        // 1. Update Unit
                        if (selectedUnitId != resident['unit']) {
                          await _apiService.put(
                            '${ApiConstants.manageResidents}${resident['id']}/',
                            {'unit_id': selectedUnitId},
                          );
                        }
                        
                        // 2. Update Parking (if changed)
                        if (selectedParkingId != (currentParking?['id'])) {
                          // Unassign old parking
                          if (currentParking != null) {
                            await _apiService.post(ApiConstants.assignParkingTenant(currentParking['id']), {'tenant_id': null});
                          }
                          // Assign new parking
                          if (selectedParkingId != null) {
                            await _apiService.post(ApiConstants.assignParkingTenant(selectedParkingId!), {'tenant_id': resident['id']});
                          }
                        }
                        
                        if (mounted) {
                          Navigator.pop(context);
                          _fetchData();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resident info updated successfully'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        debugPrint('Error saving resident: $e');
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: const Text('Manage Residents')), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Residents')),
      body: _residents.isEmpty
          ? const Center(child: Text('No residents found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _residents.length,
              itemBuilder: (context, index) {
                final r = _residents[index];
                
                // Find parking lot
                String parkingLotText = 'None';
                try {
                  final p = _parkingLots.firstWhere((p) => p['tenant'] == r['id']);
                  parkingLotText = 'Lot ${p['lot_number']}';
                } catch (_) {}

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryLight,
                      child: Text(
                        (r['first_name']?.isNotEmpty ?? false) ? r['first_name'][0].toUpperCase() : 'U',
                        style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text('${r['first_name'] ?? ''} ${r['last_name'] ?? ''}'.trim(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Flat: ${r['unit_number'] ?? 'Unassigned'}'),
                        Text('Parking: $parkingLotText'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                      onPressed: () => _showEditDialog(r),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
