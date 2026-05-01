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
  List<dynamic> _wings = [];
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
        _apiService.get(ApiConstants.wingsList),
        _apiService.get(ApiConstants.parkingLots),
      ]);

      if (mounted) {
        setState(() {
          final resData = jsonDecode(futures[0].body);
          _residents = resData is List ? List.from(resData) : List.from(resData['results'] ?? []);

          final wingsData = jsonDecode(futures[1].body);
          _wings = wingsData is List ? List.from(wingsData) : List.from(wingsData['results'] ?? []);

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: _EditResidentForm(
            resident: resident,
            wings: _wings,
            parkingLots: _parkingLots,
            onSuccess: () {
              Navigator.pop(ctx);
              _fetchData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Resident info updated successfully'), backgroundColor: Colors.green),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Residents')),
        body: const Center(child: CircularProgressIndicator()),
      );
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

                // Build unit display with wing
                String flatText = 'Unassigned';
                final ud = r['unit_details'];
                if (ud != null) {
                  flatText = '${ud['wing']}-${ud['number']}';
                } else if (r['unit_number'] != null) {
                  flatText = r['unit_number'];
                }

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
                    title: Text(
                      '${r['first_name'] ?? ''} ${r['last_name'] ?? ''}'.trim(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Flat: $flatText'),
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

// ---------------------------------------------------------------------------
// Cascading Wing → Floor → Unit edit form
// ---------------------------------------------------------------------------
class _EditResidentForm extends StatefulWidget {
  final dynamic resident;
  final List<dynamic> wings;
  final List<dynamic> parkingLots;
  final VoidCallback onSuccess;

  const _EditResidentForm({
    required this.resident,
    required this.wings,
    required this.parkingLots,
    required this.onSuccess,
  });

  @override
  State<_EditResidentForm> createState() => _EditResidentFormState();
}

class _EditResidentFormState extends State<_EditResidentForm> {
  final ApiService _apiService = ApiService();
  bool _isSaving = false;

  dynamic _selectedWing;
  String? _selectedFloor;
  dynamic _selectedUnit;
  int? _selectedParkingId;

  @override
  void initState() {
    super.initState();
    _initFromResident();
  }

  void _initFromResident() {
    final ud = widget.resident['unit_details'];
    if (ud != null) {
      // Find the wing that matches
      for (var w in widget.wings) {
        if (w['name'].toString() == ud['wing'].toString()) {
          _selectedWing = w;
          // Determine floor from unit number
          final number = ud['number'].toString();
          if (number.length >= 3 && int.tryParse(number) != null) {
            _selectedFloor = number.substring(0, number.length - 2);
          } else {
            _selectedFloor = 'G';
          }
          // Find the unit object in the wing
          final units = List.from(w['units'] ?? []);
          for (var u in units) {
            if (u['id'] == ud['id']) {
              _selectedUnit = u;
              break;
            }
          }
          break;
        }
      }
    }

    // Find current parking
    try {
      final currentParking = widget.parkingLots.firstWhere((p) => p['tenant'] == widget.resident['id']);
      _selectedParkingId = currentParking['id'];
    } catch (_) {}
  }

  // --- Derived data ---

  List<String> get _availableFloors {
    if (_selectedWing == null) return [];
    final units = List.from(_selectedWing['units'] ?? []);
    final floors = <String>{};
    for (var u in units) {
      final number = u['number'].toString();
      if (number.length >= 3 && int.tryParse(number) != null) {
        floors.add(number.substring(0, number.length - 2));
      } else {
        floors.add('G');
      }
    }
    final sorted = floors.toList()
      ..sort((a, b) {
        final ai = int.tryParse(a);
        final bi = int.tryParse(b);
        if (ai != null && bi != null) return ai.compareTo(bi);
        return a.compareTo(b);
      });
    return sorted;
  }

  List<dynamic> get _floorUnits {
    if (_selectedWing == null || _selectedFloor == null) return [];
    final units = List.from(_selectedWing['units'] ?? []);
    return units.where((u) {
      final number = u['number'].toString();
      String floor = 'G';
      if (number.length >= 3 && int.tryParse(number) != null) {
        floor = number.substring(0, number.length - 2);
      }
      return floor == _selectedFloor;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resident;

    // Find the original parking to detect changes
    dynamic originalParking;
    try {
      originalParking = widget.parkingLots.firstWhere((p) => p['tenant'] == r['id']);
    } catch (_) {}

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Manage Resident', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${r['first_name'] ?? ''} ${r['last_name'] ?? ''}'.trim(),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // --- Wing & Floor side-by-side ---
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<dynamic>(
                  value: _selectedWing,
                  decoration: const InputDecoration(
                    labelText: 'Wing',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  items: widget.wings
                      .map((w) => DropdownMenuItem(value: w, child: Text(w['name'] ?? '')))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedWing = val;
                      _selectedFloor = null;
                      _selectedUnit = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFloor,
                  decoration: const InputDecoration(
                    labelText: 'Floor',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  items: _availableFloors
                      .map((f) => DropdownMenuItem(value: f, child: Text(f == 'G' ? 'Ground' : 'Floor $f')))
                      .toList(),
                  onChanged: _selectedWing == null
                      ? null
                      : (val) {
                          setState(() {
                            _selectedFloor = val;
                            _selectedUnit = null;
                          });
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- Unit ---
          DropdownButtonFormField<dynamic>(
            value: _selectedUnit,
            decoration: const InputDecoration(
              labelText: 'Assigned Flat',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            items: _floorUnits
                .map((u) => DropdownMenuItem(value: u, child: Text('${_selectedWing?['name']}-${u['number']}')))
                .toList(),
            onChanged: _selectedFloor == null ? null : (val) => setState(() => _selectedUnit = val),
          ),
          const SizedBox(height: 16),

          // --- Parking ---
          DropdownButtonFormField<int?>(
            value: _selectedParkingId,
            decoration: const InputDecoration(
              labelText: 'Assigned Parking Lot',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('None')),
              ...widget.parkingLots.map(
                (p) => DropdownMenuItem<int?>(
                  value: p['id'],
                  child: Text('Lot ${p['lot_number']} (${p['status']})'),
                ),
              ),
            ],
            onChanged: (val) => setState(() => _selectedParkingId = val),
          ),
          const SizedBox(height: 32),

          CustomButton(
            text: 'Save Changes',
            isLoading: _isSaving,
            onPressed: () async {
              setState(() => _isSaving = true);
              try {
                // 1. Update Unit
                final newUnitId = _selectedUnit?['id'];
                if (newUnitId != null && newUnitId != r['unit']) {
                  await _apiService.put(
                    '${ApiConstants.manageResidents}${r['id']}/',
                    {'unit_id': newUnitId},
                  );
                }

                // 2. Update Parking (if changed)
                if (_selectedParkingId != originalParking?['id']) {
                  // Unassign old
                  if (originalParking != null) {
                    await _apiService.post(
                      ApiConstants.assignParkingTenant(originalParking['id']),
                      {'tenant_id': null},
                    );
                  }
                  // Assign new
                  if (_selectedParkingId != null) {
                    await _apiService.post(
                      ApiConstants.assignParkingTenant(_selectedParkingId!),
                      {'tenant_id': r['id']},
                    );
                  }
                }

                if (mounted) widget.onSuccess();
              } catch (e) {
                debugPrint('Error saving resident: $e');
                if (mounted) {
                  setState(() => _isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
