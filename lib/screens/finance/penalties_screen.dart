import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class PenaltiesScreen extends StatefulWidget {
  const PenaltiesScreen({super.key});

  @override
  State<PenaltiesScreen> createState() => _PenaltiesScreenState();
}

class _PenaltiesScreenState extends State<PenaltiesScreen> {
  final ApiService _apiService = ApiService();

  List<dynamic> _penalties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPenalties();
  }

  Future<void> _fetchPenalties() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.penalties);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _penalties = data is List ? data : (data['results'] ?? []));
      }
    } catch (e) {
      debugPrint('Error fetching penalties: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showIssuePenaltySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: _IssuePenaltyForm(
            onSuccess: () {
              Navigator.pop(context);
              _fetchPenalties();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penalty issued.'), backgroundColor: Colors.green));
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Penalties')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _penalties.isEmpty
              ? const Center(child: Text('No penalties issued.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _penalties.length,
                  itemBuilder: (context, index) {
                    final p = _penalties[index];
                    final isPaid = p['status'] == 'paid';
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: isPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          child: Icon(Icons.gavel, color: isPaid ? Colors.green : Colors.red),
                        ),
                        title: Text('₹${p['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(p['reason'] ?? 'No reason'),
                            if (p['unit_number'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Unit: ${p['wing_name'] ?? ''}${p['wing_name'] != null ? '-' : ''}${p['unit_number']}',
                                style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              isPaid ? 'PAID' : 'UNPAID',
                              style: TextStyle(color: isPaid ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: !isPaid
                            ? InkWell(
                                onTap: () async {
                                  await _apiService.patch('${ApiConstants.penalties}${p['id']}/', {'status': 'paid'});
                                  _fetchPenalties();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                  child: const Text('Mark Paid', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showIssuePenaltySheet,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Issue Penalty', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cascading Wing → Floor → Unit dropdown form
// ---------------------------------------------------------------------------
class _IssuePenaltyForm extends StatefulWidget {
  final VoidCallback onSuccess;
  const _IssuePenaltyForm({required this.onSuccess});

  @override
  State<_IssuePenaltyForm> createState() => _IssuePenaltyFormState();
}

class _IssuePenaltyFormState extends State<_IssuePenaltyForm> {
  final ApiService _apiService = ApiService();
  final _reasonController = TextEditingController();
  final _amountController = TextEditingController();

  List<dynamic> _wings = [];
  List<dynamic> _residents = [];
  bool _isLoadingData = true;
  bool _isSubmitting = false;

  dynamic _selectedWing;
  String? _selectedFloor;
  dynamic _selectedUnit;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final futures = await Future.wait([
        _apiService.get(ApiConstants.wingsList),
        _apiService.get(ApiConstants.manageResidents),
      ]);

      if (futures[0].statusCode == 200 && futures[1].statusCode == 200) {
        final wingsRaw = jsonDecode(futures[0].body);
        final resRaw = jsonDecode(futures[1].body);

        setState(() {
          _wings = wingsRaw is List ? wingsRaw : List.from(wingsRaw['results'] ?? []);
          _residents = resRaw is List ? resRaw : List.from(resRaw['results'] ?? []);
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching wing/resident data: $e');
      if (mounted) setState(() => _isLoadingData = false);
    }
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
    final sorted = floors.toList()..sort((a, b) {
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

  String _ownerName(dynamic unit) {
    if (unit == null) return 'Vacant';
    final wingName = _selectedWing?['name'];
    final unitNumber = unit['number'];

    for (var r in _residents) {
      final ud = r['unit_details'];
      if (ud != null &&
          ud['wing'].toString() == wingName.toString() &&
          ud['number'].toString() == unitNumber.toString()) {
        final first = r['first_name'] ?? '';
        final last = r['last_name'] ?? '';
        return '$first $last'.trim().isEmpty ? 'Resident' : '$first $last'.trim();
      }
    }
    return 'Vacant';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Issue New Penalty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),

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
                  items: _wings.map((w) => DropdownMenuItem(value: w, child: Text(w['name'] ?? ''))).toList(),
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

          // --- Unit with owner name ---
          DropdownButtonFormField<dynamic>(
            value: _selectedUnit,
            decoration: const InputDecoration(
              labelText: 'Unit (Owner)',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            items: _floorUnits.map((u) {
              final owner = _ownerName(u);
              return DropdownMenuItem(
                value: u,
                child: Text('${u['number']}  —  $owner'),
              );
            }).toList(),
            onChanged: _selectedFloor == null
                ? null
                : (val) => setState(() => _selectedUnit = val),
          ),
          const SizedBox(height: 16),

          // --- Reason & Amount ---
          CustomTextField(
            controller: _reasonController,
            label: 'Reason',
            hint: 'e.g. Trash placed in corridor',
            prefixIcon: Icons.report_outlined,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _amountController,
            label: 'Penalty Amount (₹)',
            hint: '500',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.currency_rupee,
          ),
          const SizedBox(height: 24),

          CustomButton(
            text: 'Issue Penalty',
            isLoading: _isSubmitting,
            onPressed: () async {
              if (_selectedUnit == null || _reasonController.text.isEmpty || _amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a unit and fill all fields')),
                );
                return;
              }

              setState(() => _isSubmitting = true);

              final response = await _apiService.post(ApiConstants.penalties, {
                'unit': _selectedUnit['id'],
                'reason': _reasonController.text,
                'amount': _amountController.text,
              });

              if (response.statusCode == 201 && mounted) {
                widget.onSuccess();
              } else if (mounted) {
                setState(() => _isSubmitting = false);
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
  }
}
