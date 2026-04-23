import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../models/gate_pass.dart';
// Note: We need to run `flutter pub add mobile_scanner` for this package.
// If you face build issues, you might need to update minSdkVersion to 21 in android/app/build.gradle
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _validateScannedPass(String barcodeData) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // The API validates whether the string has the RESIFLOW:PASS: prefix or not.
      final response = await _apiService.post(
        ApiConstants.qrValidate,
        {'pass_id': barcodeData},
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        if (response.statusCode == 200 && data['valid'] == true) {
          final pass = GatePass.fromJson(data['pass']);
          _showScanResult(true, pass, null);
        } else {
           _showScanResult(false, null, data['reason'] ?? 'Invalid QR Code');
        }
      }
    } catch (e) {
      if (mounted) {
         _showScanResult(false, null, 'Error validating QR code: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showScanResult(bool isValid, GatePass? pass, String? errorMessage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isValid ? Icons.check_circle : Icons.error,
              color: isValid ? Colors.green : Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isValid ? 'Access Granted' : 'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isValid ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            if (isValid && pass != null) ...[
              Text('Visitor: ${pass.visitorName}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text('Phone: ${pass.visitorPhone}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 4),
              Text('Persons: ${pass.numberOfPersons}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              if (pass.purpose != null && pass.purpose!.isNotEmpty) ...[
                 const SizedBox(height: 4),
                 Text('Purpose: ${pass.purpose}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ]
            ] else ...[
              Text(
                errorMessage ?? 'Unknown validation error.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _scannerController.start(); // Restart scanning manually
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Scan Next', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Gate Pass'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
             onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null && !_isProcessing) {
                     _scannerController.stop(); // Stop scanning momentarily while validating
                     _validateScannedPass(barcode.rawValue!);
                     break;
                  }
                }
             },
          ),
          
          // Scanner Overlay graphic
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(),
            ),
          ),
          
          if (_isProcessing)
            Container(
               color: Colors.black54,
               child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
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
                   'Align QR code within the frame',
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

class _ScannerOverlayPainter extends CustomPainter {
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
     
     // Draw corners markers
     final borderPaint = Paint()
       ..color = AppTheme.primaryColor
       ..style = PaintingStyle.stroke
       ..strokeWidth = 4.0;
       
     final cornerLength = 30.0;
     
     // Top Left
     canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(cornerLength, 0), borderPaint);
     canvas.drawLine(scanArea.topLeft, scanArea.topLeft + Offset(0, cornerLength), borderPaint);
     
     // Top Right
     canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(-cornerLength, 0), borderPaint);
     canvas.drawLine(scanArea.topRight, scanArea.topRight + Offset(0, cornerLength), borderPaint);
     
     // Bottom Left
     canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(cornerLength, 0), borderPaint);
     canvas.drawLine(scanArea.bottomLeft, scanArea.bottomLeft + Offset(0, -cornerLength), borderPaint);
     
     // Bottom Right
     canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(-cornerLength, 0), borderPaint);
     canvas.drawLine(scanArea.bottomRight, scanArea.bottomRight + Offset(0, -cornerLength), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
