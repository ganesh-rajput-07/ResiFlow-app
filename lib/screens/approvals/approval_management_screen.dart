import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../models/pre_approval.dart';
import '../../utils/pdf_generator.dart';

class ApprovalManagementScreen extends StatefulWidget {
  const ApprovalManagementScreen({super.key});

  @override
  State<ApprovalManagementScreen> createState() => _ApprovalManagementScreenState();
}

class _ApprovalManagementScreenState extends State<ApprovalManagementScreen> {
  final ApiService _apiService = ApiService();
  List<PreApproval> _approvals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApprovals();
  }

  Future<void> _fetchApprovals() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.preApprovals);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is List ? List.from(decoded) : List.from(decoded['results'] ?? []);
        setState(() {
          _approvals = data.map((json) => PreApproval.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('Error fetching approvals: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int id, String action) async {
    try {
      final response = await _apiService.post('${ApiConstants.preApprovals}$id/$action/', {});
      if (response.statusCode == 200) {
        _fetchApprovals(); // Refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $action successfully!')),
        );
      }
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Approvals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchApprovals,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _approvals.isEmpty 
          ? const Center(child: Text('No pre-approval requests found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _approvals.length,
              itemBuilder: (context, index) {
                final approval = _approvals[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(approval.visitorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            _StatusBadge(status: approval.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Phone: ${approval.mobile}', style: const TextStyle(color: Colors.grey)),
                        if (approval.requestedByName != null)
                           Text('Requested by: ${approval.requestedByName}'),
                        if (approval.purpose != null)
                           Text('Purpose: ${approval.purpose}'),
                        Text('Valid: ${approval.validFrom} to ${approval.validTo}'),
                        
                        if (approval.status == 'pending') ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _updateStatus(approval.id!, 'reject'),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('REJECT'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _updateStatus(approval.id!, 'approve'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('APPROVE'),
                              )
                            ],
                          )
                        ] else if (approval.status == 'approved' && approval.passId != null) ...[
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  final provider = Provider.of<AuthProvider>(context, listen: false);
                                  await PdfGenerator.generateAndShareGatePass(
                                    visitorName: approval.visitorName,
                                    validFrom: approval.validFrom,
                                    validTo: approval.validTo,
                                    purpose: approval.purpose ?? 'Visitor',
                                    passId: approval.passId!,
                                    societyName: provider.user?['society_name'] ?? 'ResiFlow Society',
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
                                }
                              },
                              icon: const Icon(Icons.qr_code, size: 18),
                              label: const Text('View Pass PDF'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                side: const BorderSide(color: AppTheme.primaryColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ]
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
    if (status == 'approved') color = Colors.green;
    else if (status == 'rejected') color = Colors.red;
    else color = Colors.orange;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
