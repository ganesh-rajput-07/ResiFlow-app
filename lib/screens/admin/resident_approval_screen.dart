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
  List<dynamic> _joinRequests = [];
  List<dynamic> _renterRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _apiService.get(ApiConstants.joinRequests),
        _apiService.get(ApiConstants.renterRequests),
      ]);
      
      if (mounted) {
        setState(() {
          final joinData = jsonDecode(futures[0].body);
          _joinRequests = joinData is List ? List.from(joinData) : List.from(joinData['results'] ?? []);
          
          final renterData = jsonDecode(futures[1].body);
          _renterRequests = renterData is List ? List.from(renterData) : List.from(renterData['results'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetching requests: $e');
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

  Future<void> _approveRenterRequest(dynamic request) async {
    final response = await _apiService.post(
      '${ApiConstants.renterRequests}${request['id']}/approve/',
      {},
    );
    if (response.statusCode == 200 && mounted) {
      _fetchRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Renter account for ${request['first_name']} has been created!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _rejectRenterRequest(dynamic request) async {
    final response = await _apiService.post(
      '${ApiConstants.renterRequests}${request['id']}/reject/',
      {'note': 'Rejected by admin'},
    );
    if (response.statusCode == 200 && mounted) {
      _fetchRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Renter request rejected.'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Approvals'),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchRequests),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Join Requests'),
              Tab(text: 'Renter Requests'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildJoinRequestsTab(),
                  _buildRenterRequestsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildJoinRequestsTab() {
    final pending = _joinRequests.where((r) => r['status'] == 'pending').toList();
    final processed = _joinRequests.where((r) => r['status'] != 'pending').toList();

    if (_joinRequests.isEmpty) return _buildEmptyState('No join requests yet');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pending.isNotEmpty) ...[
            _buildSectionHeader('${pending.length} Pending'),
            ...pending.map((r) => _buildRequestCard(r, showActions: true)),
          ],
          if (processed.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('History', color: Colors.grey),
            ...processed.map((r) => _buildRequestCard(r, showActions: false)),
          ],
        ],
      ),
    );
  }

  Widget _buildRenterRequestsTab() {
    final pending = _renterRequests.where((r) => r['status'] == 'pending').toList();
    final processed = _renterRequests.where((r) => r['status'] != 'pending').toList();

    if (_renterRequests.isEmpty) return _buildEmptyState('No renter requests yet');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pending.isNotEmpty) ...[
            _buildSectionHeader('${pending.length} Pending'),
            ...pending.map((r) => _buildRenterRequestCard(r, showActions: true)),
          ],
          if (processed.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('History', color: Colors.grey),
            ...processed.map((r) => _buildRenterRequestCard(r, showActions: false)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: (color ?? Colors.orange).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(title, style: TextStyle(color: color ?? Colors.orange, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
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

  Widget _buildRenterRequestCard(dynamic request, {required bool showActions}) {
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
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: const Icon(Icons.person_add, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${request['first_name']} ${request['last_name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Unit: ${request['wing_name']}-${request['unit_number']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(icon: Icons.phone, label: request['phone'] ?? 'N/A'),
                _InfoChip(icon: Icons.account_circle, label: 'User: ${request['username']}'),
                _InfoChip(icon: Icons.person, label: 'Owner: ${request['owner_name']}'),
              ],
            ),
            if (showActions) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _rejectRenterRequest(request),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('REJECT'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _approveRenterRequest(request),
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
