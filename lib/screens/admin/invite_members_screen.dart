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
  final _wingController = TextEditingController();
  final _flatController = TextEditingController();
  final _mobileController = TextEditingController();
  final ApiService _apiService = ApiService();

  String _inviteCode = '';
  bool _isLoadingCode = true;

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

  void _sendInvite() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invite sent to ${_mobileController.text} for Flat ${_wingController.text}-${_flatController.text}'))
    );
    _wingController.clear();
    _flatController.clear();
    _mobileController.clear();
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
                  // Real scannable QR code
                  if (_isLoadingCode)
                    const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_inviteCode.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: 'RESIFLOW:INVITE:$_inviteCode',
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppTheme.primaryDark,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    )
                  else
                    const SizedBox(
                      height: 200,
                      child: Center(child: Text('Could not load QR code', style: TextStyle(color: Colors.red))),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Society Code: $_inviteCode',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
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
            Row(
              children: [
                Expanded(child: CustomTextField(controller: _wingController, label: 'Wing', hint: 'e.g. A')),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: CustomTextField(controller: _flatController, label: 'Flat No.', hint: 'e.g. 101')),
              ],
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

