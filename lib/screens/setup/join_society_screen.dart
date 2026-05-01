import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class JoinSocietyScreen extends StatefulWidget {
  const JoinSocietyScreen({super.key});

  @override
  State<JoinSocietyScreen> createState() => _JoinSocietyScreenState();
}

class _JoinSocietyScreenState extends State<JoinSocietyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _personsController = TextEditingController(text: '1');
  final _familyDetailsController = TextEditingController();
  final _vehiclesController = TextEditingController(text: '0');
  final _parkingController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isCodeVerified = false;
  bool _isUnitInvite = false;
  String _societyName = '';
  List<dynamic> _wings = [];
  dynamic _selectedWing;
  dynamic _selectedUnit;

  Future<void> _scanQRCode() async {
    try {
      final scannedCode = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const _InviteQRScannerScreen()),
      );

      if (scannedCode != null && scannedCode.isNotEmpty && mounted) {
        setState(() {
          _codeController.text = scannedCode;
        });
        _verifyCode();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open scanner: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a code'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.societyByInvite(code));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isCodeVerified = true;
          _societyName = data['name'] ?? '';
          _wings = data['wings'] ?? [];
          _isUnitInvite = data['is_unit_invite'] ?? false;

          if (_isUnitInvite) {
            // Find the preselected wing and unit
            final preWing = data['preselected_wing'];
            final preUnit = data['preselected_unit'];
            try {
              _selectedWing = _wings.firstWhere((w) => w['name'] == preWing);
              _selectedUnit = (_selectedWing['units'] as List).firstWhere((u) => u['number'] == preUnit);
            } catch (e) {
              _selectedWing = null;
              _selectedUnit = null;
            }
          } else {
            if (_wings.isNotEmpty) {
              _selectedWing = _wings.first;
              if ((_selectedWing['units'] as List).isNotEmpty) {
                _selectedUnit = _selectedWing['units'].first;
              } else {
                _selectedUnit = null;
              }
            } else {
              _selectedWing = null;
              _selectedUnit = null;
            }
          }
        });
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid or used society code.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitJoinRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isCodeVerified || _selectedWing == null || _selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please verify code and select a unit.'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.post(
        ApiConstants.submitJoinRequest,
        {
          'invite_code': _codeController.text.trim(),
          'requested_unit': '${_selectedWing['name']}-${_selectedUnit['number']}',
          'family_members_count': int.tryParse(_personsController.text) ?? 1,
          'family_details': _familyDetailsController.text,
          'vehicles_count': int.tryParse(_vehiclesController.text) ?? 0,
          'parking_number': _parkingController.text,
        },
      );

      if (response.statusCode == 201 && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 28), SizedBox(width: 8), Text('Success!')]),
            content: Text(_isUnitInvite 
              ? 'You have been successfully added to $_societyName!'
              : 'Your request to join the society has been submitted.\n\nThe admin will review your details and approve or reject it. You will be notified once a decision is made.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back out of join screen
                },
              ),
            ],
          ),
        );
      } else if (mounted) {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error['error'] ?? 'Failed to submit request'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Society')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isCodeVerified) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Text('Scan Society QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan QR Code'),
                          onPressed: _scanQRCode,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('OR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16))),
                ),
                const Text('Society Code', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _codeController,
                        label: 'Society Invite Code',
                        hint: 'Enter Code',
                        prefixIcon: Icons.business,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Verify', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Code Verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Joining: $_societyName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (_isUnitInvite)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text('You are using a one-time pre-approved invite!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                      TextButton(
                        onPressed: () => setState(() => _isCodeVerified = false),
                        child: const Text('Change Code'),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Select Your Unit', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<dynamic>(
                        value: _selectedWing,
                        decoration: const InputDecoration(labelText: 'Wing', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                        items: _wings.map((w) => DropdownMenuItem(value: w, child: Text(w['name']))).toList(),
                        onChanged: _isUnitInvite ? null : (val) {
                          setState(() {
                            _selectedWing = val;
                            if (val != null && (val['units'] as List).isNotEmpty) {
                              _selectedUnit = val['units'].first;
                            } else {
                              _selectedUnit = null;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<dynamic>(
                        value: _selectedUnit,
                        decoration: const InputDecoration(labelText: 'Flat / Unit', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                        items: _selectedWing != null ? (_selectedWing['units'] as List).map((u) => DropdownMenuItem(value: u, child: Text(u['number']))).toList() : [],
                        onChanged: _isUnitInvite ? null : (val) => setState(() => _selectedUnit = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Additional Information', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: CustomTextField(controller: _personsController, label: 'Family Members', hint: 'Count', keyboardType: TextInputType.number)),
                    const SizedBox(width: 16),
                    Expanded(child: CustomTextField(controller: _vehiclesController, label: 'Vehicles', hint: 'Count', keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _parkingController,
                  label: 'Parking Slot Number',
                  hint: 'e.g. P-12, Basement B1',
                  prefixIcon: Icons.local_parking,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _familyDetailsController,
                  label: 'Family Details',
                  hint: 'Names & Ages of members',
                  prefixIcon: Icons.groups,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: _isUnitInvite ? 'Join Flat Now' : 'Submit Join Request',
                  onPressed: _submitJoinRequest,
                  isLoading: _isLoading,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


/// Dedicated QR scanner screen for scanning society invite QR codes.
/// Returns the extracted invite code string via Navigator.pop().
class _InviteQRScannerScreen extends StatefulWidget {
  const _InviteQRScannerScreen();

  @override
  State<_InviteQRScannerScreen> createState() => _InviteQRScannerScreenState();
}

class _InviteQRScannerScreenState extends State<_InviteQRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null || rawValue.isEmpty) continue;

      _hasScanned = true;
      _controller.stop();

      String inviteCode = rawValue.trim();
      
      if (inviteCode.startsWith('RESIFLOW:PASS:')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid QR Code! You scanned a Gate Pass instead of a Society Invite.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context, null);
        }
        return;
      }
      
      if (inviteCode.startsWith('RESIFLOW:INVITE:')) {
        inviteCode = inviteCode.replaceFirst('RESIFLOW:INVITE:', '');
      } else if (inviteCode.length > 15) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid QR Code format!'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context, null);
        }
        return;
      }

      Navigator.pop(context, inviteCode);
      break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Society QR')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanOverlayPainter(),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Point camera at society QR code',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final scanAreaSize = 250.0;
    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final cornerLength = 30.0;

    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(cornerLength, 0), borderPaint);
    canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(0, cornerLength), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(-cornerLength, 0), borderPaint);
    canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(0, cornerLength), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(cornerLength, 0), borderPaint);
    canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(0, -cornerLength), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(-cornerLength, 0), borderPaint);
    canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(0, -cornerLength), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

