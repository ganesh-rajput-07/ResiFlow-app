import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class InviteMembersScreen extends StatefulWidget {
  const InviteMembersScreen({super.key});

  @override
  State<InviteMembersScreen> createState() => _InviteMembersScreenState();
}
class _InviteMembersScreenState extends State<InviteMembersScreen> {
  final _mobileController = TextEditingController();
  final ApiService _apiService = ApiService();

  String _inviteCode = '';
  bool _isLoadingCode = true;
  List<dynamic> _wings = [];
  dynamic _selectedWing;
  String? _selectedFloor;
  dynamic _selectedUnit;

  @override
  void initState() {
    super.initState();
    _fetchSocietyDetails();
  }

  void _fetchSocietyDetails() async {
    final provider = Provider.of<AuthProvider>(context, listen: false);
    final societyId = provider.user?['society'];
    if (societyId == null) return;

    try {
      final response = await _apiService.get(ApiConstants.societyDetail(societyId));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _inviteCode = data['invite_code'] ?? '';
          _wings = data['wings'] ?? [];
          _isLoadingCode = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching society details: $e');
      if (mounted) {
        setState(() => _isLoadingCode = false);
      }
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

  void _sendInvite() async {
    if (_selectedUnit == null || _mobileController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a unit and enter mobile number.')));
      return;
    }

    final provider = Provider.of<AuthProvider>(context, listen: false);
    final societyId = provider.user?['society'];
    if (societyId == null) return;

    try {
      final response = await _apiService.post(
        ApiConstants.generateInvite(societyId),
        {'unit_id': _selectedUnit['id']},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final uniqueCode = data['invite_code'];

        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Unique Invite Generated!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('This is a ONE-TIME use code tied specifically to this flat. Once the user joins, it becomes invalid.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  Text('RESIFLOW:INVITE:$uniqueCode', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 16),
                  const Text('Sending via SMS/WhatsApp to:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_mobileController.text),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
              ],
            ),
          );
        }
        _mobileController.clear();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate unique invite code'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Residents')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Master Society QR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                  const SizedBox(height: 16),
                  if (_isLoadingCode)
                    const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                  else if (_inviteCode.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: QrImageView(
                        data: 'RESIFLOW:INVITE:$_inviteCode',
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.primaryDark),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.primaryDark),
                      ),
                    )
                  else
                    const SizedBox(height: 200, child: Center(child: Text('Could not load QR code', style: TextStyle(color: Colors.red)))),
                  const SizedBox(height: 16),
                  Text('Society Code: $_inviteCode', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  const Text('Residents can scan this QR or enter the code to join.', textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Direct Manual Invite', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),

            // --- Wing & Floor ---
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<dynamic>(
                    value: _selectedWing,
                    decoration: const InputDecoration(labelText: 'Wing', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
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
                    decoration: const InputDecoration(labelText: 'Floor', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                    items: _availableFloors.map((f) => DropdownMenuItem(value: f, child: Text(f == 'G' ? 'Ground' : 'Floor $f'))).toList(),
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
              decoration: const InputDecoration(labelText: 'Flat / Unit', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
              items: _floorUnits.map((u) => DropdownMenuItem(value: u, child: Text('${_selectedWing?['name']}-${u['number']}'))).toList(),
              onChanged: _selectedFloor == null ? null : (val) => setState(() => _selectedUnit = val),
            ),
            const SizedBox(height: 16),

            CustomTextField(controller: _mobileController, label: 'Mobile Number', hint: '10-digit number', keyboardType: TextInputType.phone, prefixIcon: Icons.phone),
            const SizedBox(height: 24),
            CustomButton(text: 'Send Invite Link via WhatsApp', onPressed: _sendInvite),
          ],
        ),
      ),
    );
  }
}

