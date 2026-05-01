import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';

class ParkingLotsScreen extends StatefulWidget {
  const ParkingLotsScreen({super.key});

  @override
  State<ParkingLotsScreen> createState() => _ParkingLotsScreenState();
}

class _ParkingLotsScreenState extends State<ParkingLotsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _parkingLots = [];
  List<dynamic> _units = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchParkingLots();
    _fetchUnits();
  }

  Future<void> _fetchUnits() async {
    try {
      final response = await _apiService.get(ApiConstants.unitsList);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _units = data is List ? List.from(data) : List.from(data['results'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetching units: $e');
    }
  }

  Future<void> _fetchParkingLots() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.parkingLots);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _parkingLots = data is List ? List.from(data) : List.from(data['results'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetching parking lots: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rentLot(int lotId, String priceStr) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rent Parking Lot'),
        content: Text('Are you sure you want to rent this parking lot for ₹$priceStr per month?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('RENT'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _apiService.post('${ApiConstants.parkingLots}$lotId/rent/', {});
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Parking lot rented successfully!'), backgroundColor: Colors.green),
          );
        }
        _fetchParkingLots();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${response.body}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelRent(int lotId) async {
    try {
      final response = await _apiService.post('${ApiConstants.parkingLots}$lotId/cancel-rent/', {});
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rent cancelled successfully!'), backgroundColor: Colors.green),
          );
        }
        _fetchParkingLots();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${response.body}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showAddOrEditDialog({Map<String, dynamic>? lot}) async {
    final isEditing = lot != null;
    final lotNumberController = TextEditingController(text: isEditing ? lot['lot_number'] : '');
    final priceController = TextEditingController(text: isEditing ? (lot['price_per_month']?.toString() ?? '') : '');
    String status = isEditing ? lot['status'] : 'self_use';
    final user = context.read<AuthProvider>().user;
    final isAdminOrComm = user?['role'] == 'admin' || user?['role'] == 'committee';
    int? selectedUnitId = isEditing ? lot['unit'] : user?['unit'];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) => AlertDialog(
          title: Text(isEditing ? 'Edit Parking Lot' : 'Add Parking Lot'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isEditing && isAdminOrComm) ...[
                  DropdownButtonFormField<int>(
                    value: selectedUnitId,
                    decoration: const InputDecoration(labelText: 'Assign to Unit'),
                    items: _units.map((u) => DropdownMenuItem<int>(
                      value: u['id'],
                      child: Text('Unit ${u['number']}'),
                    )).toList(),
                    onChanged: (val) {
                      setStateSB(() => selectedUnitId = val);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: lotNumberController,
                  decoration: const InputDecoration(labelText: 'Lot Number', hintText: 'P-101'),
                  enabled: !isEditing || isAdminOrComm,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'self_use', child: Text('Self Use')),
                    DropdownMenuItem(value: 'available', child: Text('Available for Rent')),
                  ],
                  onChanged: (val) {
                    if (val != null) setStateSB(() => status = val);
                  },
                ),
                if (status == 'available') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Rent Price (₹/month)'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                final body = {
                  'lot_number': lotNumberController.text,
                  'status': status,
                  'price_per_month': priceController.text.isNotEmpty ? priceController.text : null,
                  'unit': selectedUnitId, 
                };

                // If editing, use PUT/PATCH (we use PATCH here)
                try {
                  final response = isEditing
                      ? await _apiService.patch('${ApiConstants.parkingLots}${lot['id']}/', body)
                      : await _apiService.post(ApiConstants.parkingLots, body);

                  if (response.statusCode == 200 || response.statusCode == 201) {
                    Navigator.pop(context);
                    _fetchParkingLots();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: ${response.body}'), backgroundColor: Colors.red),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final userUnitNum = user?['unit_number'];
    final isAdminOrComm = user?['role'] == 'admin' || user?['role'] == 'committee';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Lots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchParkingLots,
          ),
        ],
      ),
      floatingActionButton: isAdminOrComm ? FloatingActionButton.extended(
        onPressed: () => _showAddOrEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Parking Lot'),
      ) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _parkingLots.isEmpty
              ? const Center(child: Text('No parking lots found in your society.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _parkingLots.length,
                  itemBuilder: (context, index) {
                    final lot = _parkingLots[index];
                    final isOwner = lot['unit_number'] == userUnitNum;
                    final isTenant = lot['tenant'] == user?['id'] || lot['tenant_name'] == (user?['first_name'] ?? user?['username']);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Lot: ${lot['lot_number']}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                _StatusBadge(status: lot['status']),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Owner: ${lot['owner_name']} (Unit ${lot['unit_number']})', style: const TextStyle(color: Colors.grey)),
                            if (lot['status'] == 'available' && lot['price_per_month'] != null)
                              Text('Rent: ₹${lot['price_per_month']}/month', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                            if (lot['status'] == 'rented' && lot['tenant_name'] != null)
                              Text('Rented by: ${lot['tenant_name']}'),
                            
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isOwner || isAdminOrComm)
                                  TextButton.icon(
                                    onPressed: () => _showAddOrEditDialog(lot: lot),
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Edit'),
                                  ),
                                if (lot['status'] == 'available' && !isOwner)
                                  ElevatedButton(
                                    onPressed: () => _rentLot(lot['id'], lot['price_per_month']?.toString() ?? '0'),
                                    child: const Text('Rent This Lot'),
                                  ),
                                if ((lot['status'] == 'rented' && (isOwner || isTenant || isAdminOrComm)))
                                  ElevatedButton(
                                    onPressed: () => _cancelRent(lot['id']),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                    child: const Text('Cancel Rent'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    if (status == 'available') {
      color = Colors.green;
      text = 'AVAILABLE';
    } else if (status == 'rented') {
      color = Colors.orange;
      text = 'RENTED';
    } else {
      color = Colors.grey;
      text = 'SELF USE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
