import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';

class VisitorLogsHistoryScreen extends StatefulWidget {
  const VisitorLogsHistoryScreen({super.key});

  @override
  State<VisitorLogsHistoryScreen> createState() => _VisitorLogsHistoryScreenState();
}

class _VisitorLogsHistoryScreenState extends State<VisitorLogsHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.visitorLogs);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _logs = data is List ? data : data['results'] ?? []);
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visitor Logs History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchLogs,
              child: _logs.isEmpty
                  ? const Center(child: Text('No visitor logs found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final inTime = DateTime.parse(log['entry_time']);
                        final outTime = log['exit_time'] != null ? DateTime.parse(log['exit_time']) : null;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(log['visitor_display_name'] ?? 'Visitor', 
                                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    if (outTime == null)
                                      const Chip(label: Text('Inside', style: TextStyle(color: Colors.blue, fontSize: 10)), backgroundColor: Color(0xFFE3F2FD))
                                    else
                                      const Chip(label: Text('Exited', style: TextStyle(color: Colors.green, fontSize: 10)), backgroundColor: Color(0xFFE8F5E9)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _InfoRow(icon: Icons.phone, text: log['visitor_phone'] ?? 'N/A'),
                                _InfoRow(icon: Icons.meeting_room, text: 'Unit: ${log['unit_name'] ?? 'N/A'} (Wing: ${log['wing_name'] ?? 'N/A'})'),
                                _InfoRow(icon: Icons.person_outline, text: 'Meeting: ${log['meeting_person'] ?? 'N/A'}'),
                                _InfoRow(icon: Icons.question_answer, text: 'Purpose: ${log['visit_purpose'] ?? 'N/A'}'),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('ENTRY', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                        Text(DateFormat('hh:mm a, dd MMM').format(inTime), style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    if (outTime != null)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('EXIT', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                          Text(DateFormat('hh:mm a, dd MMM').format(outTime), style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

