import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';

class ResidentApprovalScreen extends StatefulWidget {
  const ResidentApprovalScreen({super.key});

  @override
  State<ResidentApprovalScreen> createState() => _ResidentApprovalScreenState();
}

class _ResidentApprovalScreenState extends State<ResidentApprovalScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.joinRequests);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _requests = data is List ? data : (data['results'] ?? []));
      }
    } catch (e) {
      debugPrint('Error fetching join requests: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRequest(dynamic request) async {
    final response = await _apiService.post(
      '${ApiConstants.joinRequests}${request['id']}/approve/',
      {},
    );
    if (response.statusCode == 200 && mounted) {
      _fetchRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${request['user_name']} has been approved!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _rejectRequest(dynamic request) async {
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject ${request['user_name']}\'s join request?'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Why are you rejecting this?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await _apiService.post(
        '${ApiConstants.joinRequests}${request['id']}/reject/',
        {'note': noteController.text},
      );
      if (response.statusCode == 200 && mounted) {
        _fetchRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request rejected.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _requests.where((r) => r['status'] == 'pending').toList();
    final processed = _requests.where((r) => r['status'] != 'pending').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resident Approvals'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchRequests),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No join requests yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('When residents use your invite code, their requests will appear here.', 
                        style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pending.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text('${pending.length} Pending', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...pending.map((r) => _buildRequestCard(r, showActions: true)),
                      ],
                      if (processed.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 12),
                        ...processed.map((r) => _buildRequestCard(r, showActions: false)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildRequestCard(dynamic request, {required bool showActions}) {
    final status = request['status'] ?? 'pending';
    Color statusColor;
    switch (status) {
      case 'approved': statusColor = Colors.green; break;
      case 'rejected': statusColor = Colors.red; break;
      default: statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    (request['user_name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request['user_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('📞 ${request['user_phone'] ?? 'N/A'}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Details
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(icon: Icons.door_front_door, label: 'Unit: ${request['requested_unit']}'),
                _InfoChip(icon: Icons.people, label: 'Family: ${request['family_members_count']}'),
                _InfoChip(icon: Icons.directions_car, label: 'Vehicles: ${request['vehicles_count']}'),
                if ((request['parking_number'] ?? '').isNotEmpty)
                  _InfoChip(icon: Icons.local_parking, label: 'Parking: ${request['parking_number']}'),
              ],
            ),
            if ((request['family_details'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Family: ${request['family_details']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
            if ((request['admin_note'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Admin note: ${request['admin_note']}', style: const TextStyle(color: Colors.red, fontSize: 13, fontStyle: FontStyle.italic)),
            ],
            // Actions
            if (showActions) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _rejectRequest(request),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('REJECT'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _approveRequest(request),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('APPROVE'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
