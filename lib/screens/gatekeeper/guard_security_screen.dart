import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../scanner/qr_scanner_screen.dart';

class GuardSecurityScreen extends StatefulWidget {
  const GuardSecurityScreen({super.key});

  @override
  State<GuardSecurityScreen> createState() => _GuardSecurityScreenState();
}

class _GuardSecurityScreenState extends State<GuardSecurityScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoggedInToAttendance = false;
  Map<String, dynamic>? _activeAttendance;
  List<dynamic> _activeLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() => _isLoading = true);
    try {
      // Fetch attendance and active logs
      final futures = await Future.wait([
        _apiService.get(ApiConstants.guardAttendance),
        _apiService.get('${ApiConstants.visitorLogs}?active=true'),
      ]);

      if (futures[0].statusCode == 200) {
        final attendanceList = jsonDecode(futures[0].body);
        final list = attendanceList is List ? attendanceList : attendanceList['results'] ?? [];
        _activeAttendance = list.firstWhere((a) => a['logout_time'] == null, orElse: () => null);
        _isLoggedInToAttendance = _activeAttendance != null;
      }

      if (futures[1].statusCode == 200) {
        final logsData = jsonDecode(futures[1].body);
        _activeLogs = (logsData is List ? logsData : logsData['results'] ?? [])
            .where((l) => l['exit_time'] == null)
            .toList();
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAttendance() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.post(
        _isLoggedInToAttendance ? ApiConstants.guardLogout : ApiConstants.guardLogin,
        {},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isLoggedInToAttendance ? 'Logged in successfully' : 'Logged out successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showManualEntryForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ManualVisitorForm(onSuccess: () {
        Navigator.pop(ctx);
        _fetchStatus();
      }),
    );
  }

  Future<void> _checkoutVisitor(int id) async {
    try {
      final response = await _apiService.post('${ApiConstants.visitorCheckout}$id/checkout/', {});
      if (response.statusCode == 200) {
        _fetchStatus();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visitor checked out')));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Gate Management'),
        actions: [
          IconButton(
            icon: Icon(_isLoggedInToAttendance ? Icons.logout : Icons.login, 
                 color: _isLoggedInToAttendance ? Colors.red : Colors.green),
            onPressed: _toggleAttendance,
            tooltip: _isLoggedInToAttendance ? 'Logout Attendance' : 'Login Attendance',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Quick Actions ---
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.qr_code_scanner,
                            title: 'Scan QR',
                            color: Colors.blue,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen())),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.edit_note,
                            title: 'Manual Entry',
                            color: Colors.orange,
                            onTap: _showManualEntryForm,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Active Visitors Section ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Active Visitors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${_activeLogs.length} Inside', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_activeLogs.isEmpty)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No active visitors inside', style: TextStyle(color: Colors.grey)),
                      ))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _activeLogs.length,
                        itemBuilder: (ctx, idx) {
                          final log = _activeLogs[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                child: const Icon(Icons.person, color: Colors.blue),
                              ),
                              title: Text(log['visitor_display_name'] ?? 'Visitor', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Unit: ${log['unit_name'] ?? 'N/A'} • In: ${DateFormat('hh:mm a').format(DateTime.parse(log['entry_time']))}'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.withOpacity(0.1),
                                  foregroundColor: Colors.red,
                                  elevation: 0,
                                ),
                                onPressed: () => _checkoutVisitor(log['id']),
                                child: const Text('Exit'),
                              ),
                            ),
                          );
                        },
                      ),
                    
                    const SizedBox(height: 24),
                    // --- Attendance Status Card ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isLoggedInToAttendance ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _isLoggedInToAttendance ? Colors.green : Colors.red),
                      ),
                      child: Row(
                        children: [
                          Icon(_isLoggedInToAttendance ? Icons.check_circle : Icons.error, 
                               color: _isLoggedInToAttendance ? Colors.green : Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_isLoggedInToAttendance ? 'Attendance: Logged In' : 'Attendance: Logged Out', 
                                     style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (_isLoggedInToAttendance && _activeAttendance != null)
                                  Text('Started at: ${DateFormat('hh:mm a, dd MMM').format(DateTime.parse(_activeAttendance!['login_time']))}', 
                                       style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ManualVisitorForm extends StatefulWidget {
  final VoidCallback onSuccess;
  const _ManualVisitorForm({required this.onSuccess});

  @override
  State<_ManualVisitorForm> createState() => _ManualVisitorFormState();
}

class _ManualVisitorFormState extends State<_ManualVisitorForm> {
  final ApiService _apiService = ApiService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _purposeController = TextEditingController();
  bool _isSubmitting = false;
  
  List<dynamic> _units = [];
  int? _selectedUnitId;

  @override
  void initState() {
    super.initState();
    _fetchUnits();
  }

  Future<void> _fetchUnits() async {
    try {
      final response = await _apiService.get(ApiConstants.wingsList); // We can get units from wings
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List wings = data is List ? data : data['results'] ?? [];
        List allUnits = [];
        for (var wing in wings) {
          final units = wing['units'] ?? [];
          for (var unit in units) {
            allUnits.add({
              'id': unit['id'],
              'label': '${wing['name']} - ${unit['number']}',
            });
          }
        }
        if (mounted) setState(() => _units = allUnits);
      }
    } catch (e) {
      debugPrint('Error fetching units: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manual Visitor Entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CustomTextField(controller: _nameController, label: 'Visitor Name', hint: 'John Doe'),
            const SizedBox(height: 12),
            CustomTextField(controller: _phoneController, label: 'Phone Number', hint: '1234567890', keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Destination Unit',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              items: _units.map((u) => DropdownMenuItem<int>(value: u['id'], child: Text(u['label']))).toList(),
              onChanged: (val) {
                if (mounted) setState(() => _selectedUnitId = val);
              },
            ),
            const SizedBox(height: 12),
            CustomTextField(controller: _purposeController, label: 'Purpose', hint: 'Delivery, Guest, etc.'),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Register Entry',
              isLoading: _isSubmitting,
              onPressed: () async {
                if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _selectedUnitId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                  return;
                }
                setState(() => _isSubmitting = true);
                try {
                  final response = await _apiService.post(ApiConstants.visitorLogs, {
                    'visitor_name': _nameController.text,
                    'visitor_phone': _phoneController.text,
                    'destination_unit': _selectedUnitId,
                    'visit_purpose': _purposeController.text,
                  });
                  if (response.statusCode == 201) {
                    widget.onSuccess();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
                  }
                } catch (e) {
                  debugPrint('Error: $e');
                } finally {
                  if (mounted) setState(() => _isSubmitting = false);
                }
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
