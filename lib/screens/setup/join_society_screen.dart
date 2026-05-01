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
  final _flatController = TextEditingController();
  final _personsController = TextEditingController(text: '1');
  final _familyDetailsController = TextEditingController();
  final _vehiclesController = TextEditingController(text: '0');
  final _parkingController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;

  /// Opens the QR scanner and extracts the invite code from the scanned data.
  Future<void> _scanQRCode() async {
    try {
      final scannedCode = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const _InviteQRScannerScreen()),
      );

      if (scannedCode != null && scannedCode.isNotEmpty && mounted) {
        setState(() {
          _codeController.text = scannedCode;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invite code scanned: $scannedCode'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open scanner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitJoinRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_codeController.text.isEmpty || _flatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Society Code and Flat Number'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.post(
        ApiConstants.submitJoinRequest,
        {
          'invite_code': _codeController.text.trim(),
          'requested_unit': _flatController.text.trim(),
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
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Request Sent!'),
              ],
            ),
            content: const Text(
              'Your request to join the society has been submitted.\n\n'
              'The admin will review your details and approve or reject it. '
              'You will be notified once a decision is made.',
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['error'] ?? 'Failed to submit request'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
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
              CustomTextField(
                controller: _codeController,
                label: 'Society Invite Code',
                hint: 'Enter Code (e.g., A1B2C3D4E5)',
                prefixIcon: Icons.business,
              ),
              const SizedBox(height: 24),
              const Text('Your Details', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _flatController,
                label: 'Flat/Unit Number',
                hint: 'Flat/Unit Number (e.g. A-101)',
                prefixIcon: Icons.door_front_door,
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
                text: 'Submit Join Request',
                onPressed: _submitJoinRequest,
                isLoading: _isLoading,
              ),
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

      // Extract invite code from various QR formats:
      // 1. "RESIFLOW:INVITE:ABC123DEF4" → "ABC123DEF4"
      // 2. Plain invite code → "ABC123DEF4"
      String inviteCode = rawValue.trim();
      if (inviteCode.startsWith('RESIFLOW:INVITE:')) {
        inviteCode = inviteCode.replaceFirst('RESIFLOW:INVITE:', '');
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

