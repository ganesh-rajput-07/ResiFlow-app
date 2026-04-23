import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/gate_pass.dart';
import '../../core/constants/api_constants.dart';

class QrPassScreen extends StatelessWidget {
  final GatePass gatePass;

  const QrPassScreen({super.key, required this.gatePass});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gate Pass'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.black, fontSize: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    gatePass.visitorName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Phone: ${gatePass.visitorPhone}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  
                  // The backend saves the direct string `RESIFLOW:PASS:{id}` internally inside the QR encoder image
                  // Instead of making the app refetch the image statically via URL, we can regenerate it on frontend easily for display purposes fast.
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 2),
                    ),
                    child: QrImageView(
                      data: "RESIFLOW:PASS:${gatePass.passId}",
                      version: QrVersions.auto,
                      size: 200.0,
                      foregroundColor: AppTheme.primaryDark,
                    ),
                  ),

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'Pass ID: ${gatePass.passId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailItem('Valid From', gatePass.validFrom),
                      _buildDetailItem('Valid To', gatePass.validTo),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem('Persons', gatePass.numberOfPersons.toString()),
                  if (gatePass.purpose != null && gatePass.purpose!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailItem('Purpose', gatePass.purpose!),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
