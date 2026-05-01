import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';

class ManageComplaintsScreen extends StatefulWidget {
  const ManageComplaintsScreen({super.key});

  @override
  State<ManageComplaintsScreen> createState() => _ManageComplaintsScreenState();
}

class _ManageComplaintsScreenState extends State<ManageComplaintsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _complaints = [];

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.complaints);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _complaints = data is List ? data : (data['results'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      final response = await _apiService.patch('${ApiConstants.complaints}$id/', {'status': status});
      if (response.statusCode == 200) {
        _fetchComplaints();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Complaints')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _complaints.isEmpty
              ? const Center(child: Text('No complaints to manage.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _complaints.length,
                  itemBuilder: (context, index) {
                    final c = _complaints[index];
                    final statusColor = c['status'] == 'resolved' ? Colors.green : (c['status'] == 'in_progress' ? Colors.orange : Colors.blue);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text(c['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('By: ${c['raised_by_name'] ?? 'Resident'} (${c['wing_name'] ?? ''} - ${c['unit_number'] ?? 'N/A'})'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(c['status'].toString().toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                                const SizedBox(height: 4),
                                Text(c['description']),
                                const SizedBox(height: 16),
                                const Text('Change Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _statusButton(c['id'], 'open', Colors.blue),
                                    const SizedBox(width: 8),
                                    _statusButton(c['id'], 'in_progress', Colors.orange),
                                    const SizedBox(width: 8),
                                    _statusButton(c['id'], 'resolved', Colors.green),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _statusButton(int id, String status, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: () => _updateStatus(id, status),
      child: Text(status.replaceFirst('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 10)),
    );
  }
}
